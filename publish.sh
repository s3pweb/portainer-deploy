#!/bin/bash

echo "$2 - Only publish"

apt-get update && apt-get install -y jq;

# Build and push to Docker hub
declare -x VERSION

VERSION=$(jq -r '.version' package.json);

echo ${VERSION};

docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD};

docker build -t s3pweb/$2 -t s3pweb/$2:${VERSION} .;

docker push s3pweb/$2;
