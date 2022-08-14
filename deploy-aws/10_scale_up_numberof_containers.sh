#!/bin/bash

REGION="us-west-2"
PROFILE_NAME="ecs-tutorial"
CONFIG_NAME="ecs-tutorial"
PROJECT_NAME="sffoodtrucks"

NO_INSTANCES=2

ecs-cli compose --project-name $PROJECT_NAME \
        service scale $NO_INSTANCES --cluster-config $CONFIG_NAME \
                        --ecs-profile $PROFILE_NAME
