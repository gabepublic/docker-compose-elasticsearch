#!/bin/bash

REGION="us-west-2"

TASK_ID=""

echo "Enter the TASK_ID?"
read ID_RSA

PROFILE_NAME="ecs-tutorial"
CONFIG_NAME="ecs-ec2-tutorial"

#            --follow 
ecs-cli logs --task-id $TASK_ID \
             --cluster-config $CONFIG_NAME \
             --ecs-profile $PROFILE_NAME
