#!/bin/bash

REGION="us-west-2"

VPC_ID=""

echo "Enter the VPC_ID (vpc-***)?"
read VPC_ID

echo "retrieve the Security GroupId for $VPC_ID"

aws ec2 describe-security-groups --filters Name=vpc-id,Values=$VPC_ID \
        --region $REGION

echo "Capture the VPC Security GroupId and continue on the next step..."