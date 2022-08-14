#!/bin/bash

REGION="us-west-2"

SECGROUP_ID=""

echo "Enter the Security Group - GroupId (sg-***)?"
read SECGROUP_ID

echo "add a security group rule to allow inbound access on port 5000"

aws ec2 authorize-security-group-ingress --group-id $SECGROUP_ID \
        --protocol tcp --port 5000 --cidr 0.0.0.0/0 --region $REGION
