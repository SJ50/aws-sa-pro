#!/bin/bash

# empty S3 bucket so it can be remove by cloudformation stack
bucket1=$(aws s3 ls --profile prod | cut -f3 -d " " | awk 'NR==1')
bucket2=$(aws s3 ls --profile prod | cut -f3 -d " " | awk 'NR==2')
bucket3=$(aws s3 ls --profile prod | cut -f3 -d " " | awk 'NR==3')

aws s3 rm s3://$bucket1 --recursive --profile prod
aws s3 rm s3://$bucket2 --recursive --profile prod
aws s3 rm s3://$bucket3 --recursive --profile prod

# delete S3 bucket stack in Prod Account
S3Buckets=Buckets
aws cloudformation delete-stack \
    --stack-name $S3Buckets \
    --profile prod
    
# varifying cloudformation stack deleted    
while  [ "$(aws cloudformation describe-stacks --stack-name $S3Buckets --profile prod --query Stacks[0].StackStatus --output text)" = "DELETE_IN_PROGRESS" ]; do 
  aws cloudformation describe-stacks --stack-name $S3Buckets --profile prod --query Stacks[0].StackStatus --output text
  sleep 1
done    
echo "S3 buckets and IAM Role deleted from Prod account"

# delete bob user stack in Master Account
StackName=user-bob
aws cloudformation delete-stack \
    --stack-name $StackName

# varifying cloudformation stack deleted
while  [ "$(aws cloudformation describe-stacks --stack-name $StackName --query Stacks[0].StackStatus --output text)" = "DELETE_IN_PROGRESS" ]; do 
  aws cloudformation describe-stacks --stack-name $StackName --query Stacks[0].StackStatus --output text
  sleep 1
done 

echo "deleted IAM user bob"
echo ""
echo "cloudformation stacks deleted successfully"
echo ""
