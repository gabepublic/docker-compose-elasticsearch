#!/bin/bash

REGION="us-west-2"
PROFILE_NAME="ecs-tutorial"
CONFIG_NAME="ecs-ec2-tutorial"


ecs-cli compose scale 2 --cluster-config $CONFIG_NAME \
                        --ecs-profile $PROFILE_NAME
