#!/bin/bash

REGION="us-west-2"

PROFILE_NAME="ecs-tutorial"
CONFIG_NAME="ecs-tutorial"

TASK_ID=""
echo "Enter the TaskId?"
read TASK_ID

#            --follow 
ecs-cli logs --task-id $TASK_ID \
             --cluster-config $CONFIG_NAME \
             --ecs-profile $PROFILE_NAME

