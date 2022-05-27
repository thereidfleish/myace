# Fantastic article:
# https://runnable.com/blog/9-common-dockerfile-mistakes
#
# General rule of thumb is cheapest operations should go at the bottom
# to optimize build caching

# Set base image (host OS)
FROM python:3.9

# Set the working directory in the container
WORKDIR /app

# Upgrade pip
RUN pip install --upgrade pip

# Install dependencies before copying files.
# Now modifying the app won't reinstall dependencies
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt
# TODO: figure out how to install from setup.py
# RUN pip install .

# Copy the files to the working directory
COPY . .

# Run setup.py to install any unsatisfied requirements
RUN pip install .

# Specify the command to run on container start
CMD [ "gunicorn", "--bind", "0.0.0.0:6000", "--workers", "4", "wsgi:create_app" ]

# By default, listen on port 6000
EXPOSE 6000/tcp
