#!/bin/bash

REGION="us-west-2"
PROFILE_NAME="ecs-tutorial"
CONFIG_NAME="ecs-ec2-tutorial"

ecs-cli ps --cluster-config $CONFIG_NAME --ecs-profile $PROFILE_NAME

echo "check log using the task-id"