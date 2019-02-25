#!/bin/bash

CLUSTER=gatling
LOAD_GENERATOR_TASK=load-generator:2
REPORT_COMPILER_TASK=report-compiler:1
SUBNET=subnet-05c68361
SECURITY_GROUP=sg-06e06e281cdd6ad4d
BUCKET_PUBLIC_URL=http://gatling-demo.s3-website-eu-west-1.amazonaws.com

function usage() {
  if [[ -n "$1" ]]; then
    echo "👉 $1";
  fi
  echo "Usage: $0 [-n name-of-execution] [-s simulation-class] [-c loaders-count]"
  echo "  -n, --name               Execution name used to identify single run"
  echo "  -s, --simulation         Simulation class"
  echo "  -c, --count              Number of load generators to be spinned in Fargate"
  echo ""
  echo "Example: $0 --name 2 --simulation io.zonky.DemoSimulation --count 5"
  exit 1
}

function check_tasks() {
    if [[ -z "$1" ]]; then
        echo "no tasks to check"
        break;
    fi

    if [[ -z "$2" ]]; then
        echo "no desired task count entered"
        break;
    fi

    STOPPED_TASKS=0

    while [[ ${STOPPED_TASKS} -lt $2 ]]; do
        echo
        echo Checking tasks status ...
        TASK_METADATA=$(aws ecs describe-tasks --cluster ${CLUSTER} --task ${TASKS})
        PROVISIONING_TASKS=$(echo ${TASK_METADATA} | jq -r 'reduce .tasks[] as $s(0; if $s.lastStatus == "PROVISIONING" then .+1 else . end)')
        PENDING_TASKS=$(echo ${TASK_METADATA} | jq -r 'reduce .tasks[] as $s(0; if $s.lastStatus == "PENDING" then .+1 else . end)')
        RUNNING_TASKS=$(echo ${TASK_METADATA} | jq -r 'reduce .tasks[] as $s(0; if $s.lastStatus == "RUNNING" then .+1 else . end)')
        STOPPED_TASKS=$(echo ${TASK_METADATA} | jq -r 'reduce .tasks[] as $s(0; if $s.lastStatus == "STOPPED" then .+1 else . end)')

        echo "Provisioning tasks: ${PROVISIONING_TASKS}"
        echo "Pending tasks: ${PENDING_TASKS}"
        echo "Running tasks: ${RUNNING_TASKS}"
        echo "Stopped tasks: ${STOPPED_TASKS}"

        if [[ ${STOPPED_TASKS} -eq $2 ]]; then
            break;
        fi;

        sleep 5;
    done
}

# Parse command line parameters
while [[ $# -gt 0 ]]; do case $1 in
  -n|--name) EXECUTION_NAME="$2"; shift;shift;;
  -s|--simulation) SIMULATION="$2"; shift;shift;;
  -c|--count) COUNT="$2"; shift;shift;;
  *) echo "Unknown parameter passed: $1"; shift; shift;;
esac; done

# verify params
if [[ -z "${SIMULATION}" ]]; then usage "Simulation class is not set."; fi;
if [[ -z "${EXECUTION_NAME}" ]]; then usage "Execution name is not set."; fi;
if [[ -z "${COUNT}" ]]; then usage "Load generators count is not set."; fi;

echo Executing load generators in Fargate ...

TASKS=$(aws ecs run-task --cluster ${CLUSTER} --task-definition ${LOAD_GENERATOR_TASK} --launch-type "FARGATE" \
--network-configuration "awsvpcConfiguration={subnets=[${SUBNET}],securityGroups=[${SECURITY_GROUP}],assignPublicIp=ENABLED}" \
--overrides="containerOverrides=[{name=gatling-worker,environment=[{name=SIMULATION,value=${SIMULATION}},{name=EXECUTION_NAME,value=${EXECUTION_NAME}}]}]" \
--count ${COUNT} | jq -r .tasks[].taskArn)

echo Provisioning tasks ...
echo ${TASKS}

check_tasks "${TASKS}" ${COUNT}

echo
echo All tasks have been executed, generating report ...

TASKS=$(aws ecs run-task --cluster ${CLUSTER} --task-definition ${REPORT_COMPILER_TASK} --launch-type "FARGATE" \
--network-configuration "awsvpcConfiguration={subnets=[${SUBNET}],securityGroups=[${SECURITY_GROUP}],assignPublicIp=ENABLED}" \
--overrides="containerOverrides=[{name=gatling-worker,environment=[{name=EXECUTION_NAME,value=${EXECUTION_NAME}}]}]" \
--count 1 | jq -r .tasks[].taskArn)

check_tasks "${TASKS}" 1

REPORT_URL="${BUCKET_PUBLIC_URL}/results-${EXECUTION_NAME}/index.html"
echo
echo Opening generated report ${REPORT_URL} ...
open ${REPORT_URL}

echo Done!