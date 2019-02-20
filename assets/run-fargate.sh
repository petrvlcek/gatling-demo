#!/bin/sh

# Task metadata
TASK_METADATA=$(curl --silent ${ECS_CONTAINER_METADATA_URI}/task 2>&1)
TASK_ARN=$(echo ${TASK_METADATA} | jq -r .TaskARN)
TASK_ID=${TASK_ARN##*/}

if [ -z "${SIMULATION}" ]; then
  echo "SIMULATION variable is not set"
  exit 1;
fi

if [ -z "${EXECUTION_NAME}" ]; then
  echo "EXECUTION_NAME variable is not set"
  exit 1;
fi

echo Checking Logstash
curl -XGET 'logstash.local:9600/?pretty'

echo Running tests...

java -jar /gatling/simulations.jar --no-reports --simulation ${SIMULATION} --run-description "${EXECUTION_NAME}"

aws s3 cp /gatling/results/*/simulation.log s3://gatling-demo/results-${EXECUTION_NAME}/simulation-${TASK_ID}.log