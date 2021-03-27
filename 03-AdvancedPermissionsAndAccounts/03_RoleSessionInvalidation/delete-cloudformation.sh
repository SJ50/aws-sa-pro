#!/bin/bash

# find instance role
EC2RoleName=$(aws iam list-roles --query 'Roles[?contains(RoleName, `InstanceRole`) == `true`]|[0].RoleName' --output text)

#delete Instance role policy 
PolicyName=$(aws iam list-role-policies --role-name $EC2RoleName --query PolicyNames[] --output text)
aws iam delete-role-policy --role-name $EC2RoleName --policy-name $PolicyName

#delete role

#aws iam delete-role --role-name $EC2RoleName

# delete cloudformation stack
echo "deleting cloudformation stack"

aws cloudformation delete-stack --stack-name A4LHostingInc

while  [ "$(aws cloudformation describe-stacks --stack-name A4LHostingInc --query Stacks[0].StackStatus --output text)" = "DELETE_IN_PROGRESS" ]; do 
  aws cloudformation describe-stacks --stack-name A4LHostingInc --query Stacks[0].StackStatus --output text
  sleep 1
done

echo "cloud formation stack deleted successfully"

