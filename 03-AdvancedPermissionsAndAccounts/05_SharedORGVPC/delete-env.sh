#!/bin/bash

#  set cli mode to partial
export AWS_CLI_AUTO_PROMPT=on-partial

# find Security Group ID
nondefault_VPC_ID=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=false --query Vpcs[].VpcId --profile prod --output text)
SG_ID=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$nondefault_VPC_ID --query SecurityGroups[].GroupId --output text --profile prod)

# find running EC2 Instance ID in PROD Account
PROD_EC2_ID=$(aws ec2 describe-instances --query 'Reservations[].Instances[].InstanceId' --filters Name=instance-state-code,Values=[16] --profile prod --output text)

# Terminate EC2 Instance
aws ec2 terminate-instances --instance-ids $PROD_EC2_ID --profile prod

# find Security Group ID
nondefault_VPC_ID=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=false --query Vpcs[].VpcId --profile prod --output text)
SG_ID=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$nondefault_VPC_ID --query SecurityGroups[].GroupId --output text --profile prod)

# delete Security Group
aws ec2 delete-security-group --group-id $SG_ID --profile prod 

# delete resource share
ramArn=$(aws ram get-resource-shares --resource-owner SELF --query 'resourceShares[?status == `ACTIVE`]|[0].resourceShareArn' --output text)
aws ram delete-resource-share --resource-share-arn $ramArn

# delete NAT GateWay stack
StackName_NGW=NatGW
aws cloudformation delete-stack \
    --stack-name $StackName_NGW 
    
# varifying cloudformation stack deleted  
#while  [ "$(aws cloudformation describe-stacks --stack-name $StackName_NGW --query Stacks[0].StackStatus --output text)" = "DELETE_IN_PROGRESS" ]; do 
#  aws cloudformation describe-stacks --stack-name $StackName_NGW --profile prod --query Stacks[0].StackStatus --output text
#  sleep 1
#done    
#echo "NAT GateWay stack deleted"
#echo ""

# delete NAT GateWay stack
StackName=vpc
aws cloudformation delete-stack \
    --stack-name $StackName 
    
# varifying cloudformation stack deleted  
while  [ "$(aws cloudformation describe-stacks --stack-name $StackName --query Stacks[0].StackStatus --output text)" = "DELETE_IN_PROGRESS" ]; do 
  aws cloudformation describe-stacks --stack-name $StackName --profile prod --query Stacks[0].StackStatus --output text
  sleep 1
done    
echo "VPC stack deleted"






