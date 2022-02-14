from aws import AWS
import time
import json
import base64
import os


def _generate_cookies(policy: tuple, signature: str, cf_key_id: str) -> dict:
    return {
        "CloudFront-Policy": policy,
        "CloudFront-Signature": signature,
        "CloudFront-Key-Pair-Id": cf_key_id
    }


def _replace_unsupported_chars(message: str) -> str:
    return message.replace("+", "-").replace("=", "_").replace("/", "~")


class CookieSigner:

    def __init__(self, aws: AWS, expiration_in_hrs: int, cf_key_id: str):
        self.aws = aws
        self.expiration_in_hrs = expiration_in_hrs
        self.__cf_key_id = cf_key_id
        self.object_url_header = os.environ.get("S3_OBJECT_URL_HEADER")

    def _expiration_time(self) -> int:
        return int(time.time()) + (self.expiration_in_hrs * 3600)

    def _generate_policy_cookie(self, url: str) -> tuple:
        policy_dict = {
            "Statement": [
                {
                    "Resource": url,
                    "Condition": {
                        "DateLessThan": {
                            "AWS:EpochTime": self._expiration_time()
                        }
                    }
                }
            ]
        }

        # Using separators=(',', ':') removes seperator whitespace
        policy_json = json.dumps(policy_dict, separators=(",", ":"))

        policy_64 = str(base64.b64encode(policy_json.encode("utf-8")), "utf-8")
        policy_64 = _replace_unsupported_chars(policy_64)
        return policy_json, policy_64

    def _generate_signature(self, policy: json) -> str:
        sig_bytes = self.aws.rsa_sign(policy.encode('utf-8'))
        sig_64 = _replace_unsupported_chars(str(base64.b64encode(sig_bytes), "utf-8"))
        return sig_64

    def generate_signed_cookies(self, url: str) -> dict:
        policy_json, policy64 = self._generate_policy_cookie(url)
        signature = self._generate_signature(policy_json)
        return _generate_cookies(policy64, signature, self.__cf_key_id)
