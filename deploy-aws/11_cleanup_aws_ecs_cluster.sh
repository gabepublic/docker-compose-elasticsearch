#!/bin/bash

REGION="us-west-2"
PROFILE_NAME="ecs-tutorial"
CONFIG_NAME="ecs-tutorial"
PROJECT_NAME="sffoodtrucks"

ecs-cli compose --project-name $PROJECT_NAME \
        service down --cluster-config $CONFIG_NAME \
                     --ecs-profile $PROFILE_NAME

ecs-cli down --force --cluster-config $CONFIG_NAME \
             --ecs-profile $PROFILE_NAME