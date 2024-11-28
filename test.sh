#!/bin/bash

PLATFORM=qcp
BRANCH=dev
REGION=primary
REPOSITORY=testing


AWS_CONFIG_PATH=/tmp/aws_config
AWS_ACCOUNT_DATA_BASE64=$(cat /tmp/github_aws_account_data.json)
AWS_ACCOUNT_DATA=$(echo $AWS_ACCOUNT_DATA_BASE64 | base64 -d | jq ".${PLATFORM}.${BRANCH}")
AWS_ACCOUNT_DATA_REGIONAL=$(echo $AWS_ACCOUNT_DATA_BASE64 | base64 -d | jq ".${PLATFORM}.${BRANCH}.${REGION}")

for s in $(echo $AWS_ACCOUNT_DATA_REGIONAL | jq -r "to_entries|map(\"AWS_\(.key | ascii_upcase)=\(.value|tostring)\")|.[]" ); do
    export $s
done

export AWS_ACCOUNT_ID=$(echo $AWS_ACCOUNT_DATA | jq -r '.account_id')
export AWS_DOMAIN_HOSTED_ZONE_ID=$(echo $AWS_ACCOUNT_DATA | jq -r '.hosted_zone_id')
export DOMAIN_NAME=$(echo $AWS_ACCOUNT_DATA | jq -r '.domain_name')
export AWS_REGION=$(echo $AWS_ACCOUNT_DATA_REGIONAL | jq -r '.region')

echo "[default]" > $AWS_CONFIG_PATH
echo "region = ${AWS_REGION}" >> $AWS_CONFIG_PATH
echo "credential_process=vault-aws-credential-helper ${AWS_REGION} github-${REPOSITORY}-${BRANCH} ${AWS_ACCOUNT_ID} vault/github/github-${REPOSITORY}-${BRANCH}" >>  $AWS_CONFIG_PATH
echo "" >> $AWS_CONFIG_PATH


for p in $(echo $AWS_ACCOUNT_DATA_BASE64 | base64 -d | jq -r "to_entries | .[] | .key"); do
    for b in $(echo $AWS_ACCOUNT_DATA_BASE64 | base64 -d | jq -r ".${p} | to_entries | .[] | .key"); do

        account_id=$(echo $AWS_ACCOUNT_DATA_BASE64 | base64 -d | jq -r ".${p}.${b}.account_id")

        echo "[profile ${p}_${b}]" >> $AWS_CONFIG_PATH
        echo "region = ${AWS_REGION}" >> $AWS_CONFIG_PATH
        echo "credential_process=vault-aws-credential-helper ${AWS_REGION} github-${REPOSITORY}-${BRANCH} ${account_id} vault/github/github-${REPOSITORY}-${BRANCH}" >>  $AWS_CONFIG_PATH
        echo "" >> $AWS_CONFIG_PATH
        
    done
done
