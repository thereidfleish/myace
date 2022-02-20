#!/usr/bin/env python3
"""This script automatically builds, pushes, and deploys the backend API to Amazon Lightsail"""

import json
import re
import subprocess
import time

def build() -> None:
    """Build the Docker image"""
    result = subprocess.run(["docker", "build", "-t", "myace-api-prod", "./src"], check=True, capture_output=True, text=True)
    print(result.stderr)
    print(result.stdout)
    print("Image built!")


def push() -> int:
    """Push the Docker image to Lightsail and get the image version"""
    result = subprocess.run(["aws", "lightsail", "push-container-image", "--region", "us-east-2", "--service-name", "tennistrainerapi", "--label", "tennistrainer", "--image", "myace-api-prod"],
        capture_output=True, text=True
    )
    assert result.returncode == 0, f"Failed to push image. Here's some info: \n{result.stdout}\n{result.stderr}"
    # Get the image version from STDOUT
    version_pattern = r"Refer to this image as \":tennistrainerapi\.tennistrainer\.(\d+)\" in deployments\."
    match = re.search(version_pattern, result.stdout)
    assert match
    version = int(match.group(1))
    print("Image pushed!")
    return version


def _get_active_env() -> dict:
    """Get the environment variables for the active container"""
    result = subprocess.run(["aws", "lightsail", "get-container-services", "--query", "containerServices[].currentDeployment.containers.tennistrainerapi.environment", "--region", "us-east-2"], capture_output=True, text=True)
    assert result.returncode == 0, f"Failed to get currentDeployment environment. Here's some info: \n{result.stdout}\n{result.stderr}"
    result = json.loads(result.stdout)
    return result[0]


def deploy(image_version: int) -> int:
    """Deploy the specified image version on Lightsail and return the deployment version"""
    sec_waiting = 0
    while True:
        env = _get_active_env()
        result = subprocess.run(["aws", "lightsail", "create-container-service-deployment",
            "--region",
            "us-east-2",
            "--service-name",
            "tennistrainerapi",
            "--containers",
            '{ "tennistrainerapi": { "image": ":tennistrainerapi.tennistrainer.'+ str(image_version) +'","environment": ' + json.dumps(env) + ',"ports": {"6000": "HTTP"}}}',
            "--public-endpoint",
            '{"containerName": "tennistrainerapi","containerPort": 6000,"healthCheck": {"path": "/health/","successCodes": "200-499"}}'
        ], capture_output=True, text=True)
        # Repeat if Lightsail is already deploying
        if result.returncode == 254:
            print(f"Failed to create deployment because Lightsail is already busy activating another deployment. Waiting for {sec_waiting} seconds.")
            sec_waiting += 15
            time.sleep(15)
            continue
        assert result.returncode == 0, f"Failed to create deployment. Here's some info: \n{result.stdout}\n{result.stderr}"
        print("Image deployment created!")
        # Get deployment version
        deployment = json.loads(result.stdout)["containerService"]["nextDeployment"]
        deployment_version = int(deployment["version"])
        return deployment_version


def check_deployment(deployment_version: int) -> int:
    """Check the status of a deployment version

    :return: 0 (success), 1 (error), 2 (pending)
    """
    # Get the deployment
    result = subprocess.run(["aws", "lightsail", "get-container-service-deployments", "--service-name", "tennistrainerapi", "--region", "us-east-2"],
        check=True, capture_output=True, text=True
    )
    deployments = json.loads(result.stdout)["deployments"]
    deployment = next((d for d in deployments if int(d["version"]) == deployment_version), None)
    assert deployment is not None, "Invalid deployment version!"
    # Check deployment state
    if deployment["state"] == "ACTIVE":
        return 0
    elif deployment["state"] == "ACTIVATING":
        return 2
    else:
        return 1


def main():
    try:
        build()
        image_version = push()
        deployment_version = deploy(image_version)
        # Standby for deploy status
        s = 0
        while True:
            status = check_deployment(deployment_version)
            if status == 0:
                print(f"Image successfully deployed! Deployment v{deployment_version}")
                break
            elif status == 1:
                print(f"Image deployment failed! Check the logs for errors. Deployment v{deployment_version}")
                break
            else:
                print(f"Waiting for successful deployment from deployment v{deployment_version} for {s} seconds.")
                time.sleep(15)
                s += 15
    except Exception as e:
        print("""Uh oh! Something went wrong. Please ensure that:
    - You have permission to run Docker (`docker ps`)
        - If running with sudo, use `sudo -E ./deploy.py` to maintain AWS credentials
        - If not running with sudo, ensure you are in the 'docker' group (`groups`)
    - aws-cli v2+ is installed (`aws --version`)
    - AWS credentials are valid (`aws configure`)
    - The lightsailctl plugin is installed
        """)
        raise


if __name__ == "__main__":
    main()
