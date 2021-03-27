#!/bin/bash

#  set cli mode to partial
aws configure set cli_auto_prompt on-partial

# create cloudformation stack
aws cloudformation create-stack --stack-name A4LHostingInc --template-body file://01_DEMOSETUP/A4LHostingInc.yaml --capabilities CAPABILITY_IAM

#check creat completion of stack
while  [ "$(aws cloudformation describe-stacks --stack-name A4LHostingInc --query Stacks[0].StackStatus --output text)" != "CREATE_COMPLETE" ]; do 
  aws cloudformation describe-stacks --stack-name A4LHostingInc --query Stacks[0].StackStatus --output text
  sleep 1
done


#find physical ID of instances and assign to variables
EC2InstaceAID=$(aws cloudformation describe-stack-resource --stack-name A4LHostingInc --logical-resource-id EC2InstanceA --query StackResourceDetail.PhysicalResourceId --output text)
EC2InstaceBID=$(aws cloudformation describe-stack-resource --stack-name A4LHostingInc --logical-resource-id EC2InstanceB --query StackResourceDetail.PhysicalResourceId --output text)

#find ipv4 address
EC2InstaceAIPv4=$(aws ec2 describe-instances --instance-ids $EC2InstaceAID --query Reservations[].Instances[].PublicIpAddress --output text)
EC2InstaceBIPv4=$(aws ec2 describe-instances --instance-ids $EC2InstaceBID --query Reservations[].Instances[].PublicIpAddress --output text)
EC2InstaceAIPv4DNS=$(aws ec2 describe-instances --instance-ids $EC2InstaceAID --query Reservations[].Instances[].PublicDnsName --output text)
EC2InstaceBIPv4DNS=$(aws ec2 describe-instances --instance-ids $EC2InstaceBID --query Reservations[].Instances[].PublicDnsName --output text)

echo ""
echo "Instance A IPv4 = $EC2InstaceAIPv4"
echo "Instance A IPv4 DNS Name = $EC2InstaceAIPv4DNS"
echo ""
echo "Instance B IPv4 = $EC2InstaceBIPv4"
echo "Instance B IPv4 DNS Name = $EC2InstaceBIPv4DNS"

# dirty way to find instace role
EC2RoleName=$(aws iam list-roles --query Roles[].RoleName | grep InstanceRole | cut -f2 -d "\"")
echo ""
echo "Instance ROLE Name = $EC2RoleName"
echo ""
echo "follow tutorial from 6:20"
echo "command to run in EC2 instace to find 'AccessKeyId' 'SecretAccessKey' 'Token' is as follows"
echo "curl http://169.254.169.254/latest/meta-data/iam/security-credentials/$EC2RoleName"



