#!/bin/bash

#  set cli mode to partial
export AWS_CLI_AUTO_PROMPT=on-partial

# create cloudformation stack
echo "creating VPC and subnets"
StackName=vpc
aws cloudformation create-stack --stack-name $StackName \
    --template-body file://01_DEMOSETUP/01_A4L_VPC_v3.yaml \
    --capabilities CAPABILITY_IAM
    
# varifying cloudformation creation
while  [ "$(aws cloudformation describe-stacks --stack-name $StackName --query Stacks[0].StackStatus --output text)" != "CREATE_COMPLETE" ]; do 
  aws cloudformation describe-stacks --stack-name $StackName --query Stacks[0].StackStatus --output text
  sleep 1
done

echo "VPC and subnet created"

StackName_NGW=NatGW
aws cloudformation create-stack --stack-name $StackName_NGW \
    --template-body file://01_DEMOSETUP/02_A4L_NATGateways.yaml 
    
# varifying cloudformation creation
while  [ "$(aws cloudformation describe-stacks --stack-name $StackName_NGW --query Stacks[0].StackStatus --output text)" != "CREATE_COMPLETE" ]; do 
  aws cloudformation describe-stacks --stack-name $StackName_NGW --query Stacks[0].StackStatus --output text
  sleep 1
done

echo "Nat Gateway created"
echo ""
echo "enabling RAM resource sharing with aws organization, so to skip process of invite and accept within organization"
aws ram enable-sharing-with-aws-organization

# find VPC_ID
# nondefault_VPC_Name=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=false --query 'Vpcs[].{Name:Tags[?Key==`Name`].Value|[0]}' --output text)
# nondefault_VPC_CIDRBlock=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=false --query Vpcs[].CidrBlock)
# nondefault_VPC_detail=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=false --query 'Vpcs[*].{VpcId:VpcId,Name:Tags[?Key==`Name`].Value|[0],CidrBlock:CidrBlock}' --output text)
nondefault_VPC_ID=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=false --query Vpcs[].VpcId --output text)

# find subnet ARNs
SubnetArn=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$nondefault_VPC_ID --query Subnets[].SubnetArn --output text)

#find non master AccountID
PRODAccountID=$(aws sts get-caller-identity --query Account --profile prod --output text)
DEVAccountID=$(aws sts get-caller-identity --query Account --profile dev --output text)

# share resources
aws ram create-resource-share --name VPC --resource-arns $SubnetArn --no-allow-external-principals --principal $PRODAccountID $DEVAccountID
