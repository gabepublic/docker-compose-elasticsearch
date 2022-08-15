#!/bin/bash

REGION="us-west-2"
PROFILE_NAME="ecs-tutorial"
CONFIG_NAME="ecs-ec2-tutorial"

echo "deploy the cluster "

ecs-cli compose up --create-log-groups \
                   --cluster-config $CONFIG_NAME \
                   --ecs-profile $PROFILE_NAME