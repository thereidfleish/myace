# Fantastic article:
# https://runnable.com/blog/9-common-dockerfile-mistakes
#
# General rule of thumb is cheapest operations should go at the bottom
# to optimize build caching

# Set base image (host OS)
FROM python:3.9

# Set the working directory in the container
WORKDIR /app

# Install dependencies before copying files.
# Now modifying the app won't reinstall dependencies
RUN pip install -e .

# Copy the files to the working directory
COPY . .

# Specify the command to run on container start
CMD [ "gunicorn", "--bind", "0.0.0.0:6000", "--workers", "4", "wsgi:app" ]

# By default, listen on port 6000
EXPOSE 6000/tcp
