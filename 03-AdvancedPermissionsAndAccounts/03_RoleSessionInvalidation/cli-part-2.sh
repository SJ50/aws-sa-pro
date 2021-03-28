#!/bin/bash

#  set cli mode to partial
export AWS_CLI_AUTO_PROMPT=on-partial

#revoke session of role

# dirty way to find instance role
EC2RoleName=$(aws iam list-roles --query Roles[].RoleName | grep InstanceRole | cut -f2 -d "\"")

#find physical ID of instances and assign to variables
EC2InstaceA_ID=$(aws cloudformation describe-stack-resource --stack-name A4LHostingInc --logical-resource-id EC2InstanceA --query StackResourceDetail.PhysicalResourceId --output text)
EC2InstaceB_ID=$(aws cloudformation describe-stack-resource --stack-name A4LHostingInc --logical-resource-id EC2InstanceB --query StackResourceDetail.PhysicalResourceId --output text)

#find EC2 instance role association ID
EC2InstaceA_AssociationID=$(aws ec2 describe-iam-instance-profile-associations --filters Name=instance-id,Values=[$EC2InstaceA_ID] --query IamInstanceProfileAssociations[].AssociationId --output text)
EC2InstaceB_AssociationID=$(aws ec2 describe-iam-instance-profile-associations --filters Name=instance-id,Values=[$EC2InstaceB_ID] --query IamInstanceProfileAssociations[].AssociationId --output text)

#find Instance profile name
Instace_Profile_Arn=$(aws ec2 describe-iam-instance-profile-associations --filters Name=instance-id,Values=[$EC2InstaceA_ID] --query IamInstanceProfileAssociations[].IamInstanceProfile[].Arn --output text)

#Instead of rebooting EC2 instance reassociate Instance Profile 
echo "reassociating Instance A Instance Profile"
aws ec2 disassociate-iam-instance-profile --association-id $EC2InstaceA_AssociationID
aws ec2 associate-iam-instance-profile --instance-id $EC2InstaceA_ID --iam-instance-profile Arn=$Instace_Profile_Arn
echo "reassociating Instance B Instance Profile"
aws ec2 disassociate-iam-instance-profile --association-id $EC2InstaceB_AssociationID
aws ec2 associate-iam-instance-profile --instance-id $EC2InstaceB_ID --iam-instance-profile Arn=$Instace_Profile_Arn
echo "reassociation finished"

