#!/bin/bash

# Set portainer's variables
if [[ $2 = "PROD" ]]; then
    echo "Setting portainer ENV to PROD"
    declare -x PORTAINER_USER=${PROD_PORTAINER_USER}
    declare -x PORTAINER_PASSWORD=${PROD_PORTAINER_PASSWORD}
    declare -x PORTAINER_URL=${PROD_PORTAINER_URL}
    declare -x PORTAINER_SWARMID=${PROD_PORTAINER_SWARMID}
    declare -x COMPOSE_FILE="./docker-compose.yaml"
else
    echo "Setting portainer ENV to DEV"
    declare -x PORTAINER_USER=${DEV_PORTAINER_USER}
    declare -x PORTAINER_PASSWORD=${DEV_PORTAINER_URL}
    declare -x PORTAINER_URL=${DEV_PORTAINER_URL}
    declare -x PORTAINER_SWARMID=${DEV_PORTAINER_SWARMID}
    declare -x COMPOSE_FILE="./docker-compose-DEV.yaml"
fi;

# Install JQ to process JSON
apt-get update && apt-get install -y jq

# Log in to portainer API to get the TOKEN
declare -x RESPONSE=$(curl -s --header "Content-Type:application/json" \
    --request POST \
    --data '{"Username":"'${PORTAINER_USER}'","Password":"'${PORTAINER_PASSWORD}'"}' \
    "${PORTAINER_URL}/api/auth")

declare -x ERR=$(jq -r '.err' <<< ${RESPONSE})

if [[ ${ERR} != null ]]; then exit 1; fi

declare -x TOKEN=$(jq -r '.jwt' <<< ${RESPONSE})

# Check if the stack already exist
declare -x RESPONSE=$(curl --header "Content-Type:application/json" \
    --header "Authorization:Bearer ${TOKEN}" \
    --request GET "${PORTAINER_URL}/api/stacks")

declare -x INDEX=$(jq -r '.[] | select(.Name == "'$1'") | .Id' <<< ${RESPONSE})

if [[ ${INDEX} != "" ]]; then
    echo "Removing old stack"
    echo
    declare -x RESPONSE=$(curl --header "Content-Type:application/json" \
        --header "Authorization:Bearer ${TOKEN}" \
        --request DELETE \
        "${PORTAINER_URL}/api/stacks/${INDEX}");
    echo ${RESPONSE}
fi;

# Create the new stack
declare -x RESPONSE=$(curl --header "Content-Type:application/json" \
    --header "Authorization:Bearer ${TOKEN}" \
    --request POST \
    --data-binary "{
      \"Name\": \"$1\",
      \"SwarmID\": \"${PORTAINER_SWARMID}\",
      \"RepositoryURL\": \"https://bitbucket.org/s3pweb/$3\",
      \"ComposeFilePathInRepository\": \"${COMPOSE_FILE}\",
      \"RepositoryAuthentication\": true,
      \"RepositoryUsername\": \"${BITBUCKET_EMAIL}\",
      \"RepositoryPassword\": \"${BITBUCKET_PASSWORD}\"
    }" \
    "${PORTAINER_URL}/api/stacks?type=1&method=repository&endpointId=1");

echo ${RESPONSE}

declare -x ERR=$(jq -r '.err' <<< ${RESPONSE})

if [[ ${ERR} != null && ${ERR} != "" ]]; then exit 1; fi
