#!/bin/sh

# Task metadata
TASK_METADATA=$(curl --silent ${ECS_CONTAINER_METADATA_URI}/task 2>&1)
TASK_ARN=$(echo ${TASK_METADATA} | jq -r .TaskARN)
TASK_ID=${TASK_ARN##*/}

echo Task ARN: ${TASK_ARN};

if [ -z "${EXECUTION_NAME}" ]; then
  echo "EXECUTION_NAME variable is not set"
  exit 1;
fi

echo Compiling report...

aws s3 cp s3://gatling-demo/results-${EXECUTION_NAME} /gatling/results --recursive

java -jar /gatling/simulations.jar --reports-only /gatling/results

rm /gatling/results/simulation*.log
aws s3 cp /gatling/results s3://gatling-demo/results-${EXECUTION_NAME} --recursive