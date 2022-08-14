#!/bin/bash

REGION="us-west-2"
PROFILE_NAME="ecs-tutorial"
CONFIG_NAME="ecs-tutorial"
PROJECT_NAME="sffoodtrucks"

echo "deploying cluster $PROJECT_NAME..."

ecs-cli compose --project-name $PROJECT_NAME \
        service up --create-log-groups \
                   --cluster-config $CONFIG_NAME \
                   --ecs-profile $PROFILE_NAME
