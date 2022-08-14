#!/bin/bash

REGION="us-west-2"

PROFILE_NAME="ecs-tutorial"
CONFIG_NAME="ecs-tutorial"
CLUSTER_NAME="ecs-cluster-sffoodtrucks"

echo "Create cluster $CLUSTER_NAME, config ecs-tutorial, launch type FARGATE in $REGION"

ecs-cli configure --cluster $CLUSTER_NAME \
                  --default-launch-type FARGATE \
                  --config-name $CONFIG_NAME \
                  --region $REGION

echo "Create AWS cloud cluster based on cli config $CONFIG_NAME and profile $PROFILE_NAME ..."

ecs-cli up --cluster-config $CONFIG_NAME \
           --ecs-profile $PROFILE_NAME

echo "Capture the VPC_ID and continue on the next step..."