#!/bin/bash

REGION="us-west-2"
CLUSTER_NAME="ecs-ec2-tutorial"
PROFILE_NAME="ecs-tutorial"
CONFIG_NAME="ecs-ec2-tutorial"

echo "Create a cluster ecs-ec2-tutorial, config ecs-ec2-tutorial, launch type EC2 in $REGION"

ecs-cli configure --cluster $CLUSTER_NAME \
                  --default-launch-type EC2 \
                  --config-name $CONFIG_NAME \
                  --region $REGION
