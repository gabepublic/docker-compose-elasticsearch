#!/bin/bash

REGION="us-west-2"
PROFILE_NAME="ecs-tutorial"
CONFIG_NAME="ecs-ec2-tutorial"

ecs-cli compose down --cluster-config $CONFIG_NAME \
                     --ecs-profile $PROFILE_NAME

ecs-cli down --force --cluster-config $CONFIG_NAME \
             --ecs-profile $PROFILE_NAME