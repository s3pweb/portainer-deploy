#!/bin/bash

echo "$2 - Branch is $1"

# Init GIT info
git config --global push.default simple
git config user.name "$BITBUCKET_USERNAME"
git config user.email "$BITBUCKET_EMAIL"

apt-get update && apt-get install -y jq;

# Update minor version, tag and commit
if [[ $1 = master ]]; then
    npm version minor -m "ci: updated version to %s";
else
    npm version patch -m "ci: updated version to %s";
fi;

if [[ $1 = master ]]; then
    git tag;
    git remote -v;
    git push origin --tags;
fi

# Build and push to Docker hub
declare -x VERSION=$(jq -r '.version' package.json);

echo $VERSION;

sed s/:\\\${IMAGE_TAG}/:$VERSION/g docker-compose-TEMPLATE.yaml > docker-compose.yaml;

git commit -a -m "ci: updated docker-compose to version ${VERSION}";

git push;

docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD;

docker build -t s3pweb/$2 -t s3pweb/$2:$VERSION .;

docker push s3pweb/$2;
