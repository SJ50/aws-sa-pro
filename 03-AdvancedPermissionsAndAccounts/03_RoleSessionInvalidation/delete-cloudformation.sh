#!/bin/bash

# dirty way to find instance role
EC2RoleName=$(aws iam list-roles --query Roles[].RoleName | grep InstanceRole | cut -f2 -d "\"")

#delete Instance role policy 
PolicyName=$(aws iam list-role-policies --role-name $EC2RoleName --query PolicyNames[] --output text)
aws iam delete-role-policy --role-name $EC2RoleName --policy-name $PolicyName

#delete role

#aws iam delete-role --role-name $EC2RoleName

# delete cloudformation stack
aws cloudformation delete-stack --stack-name A4LHostingInc
