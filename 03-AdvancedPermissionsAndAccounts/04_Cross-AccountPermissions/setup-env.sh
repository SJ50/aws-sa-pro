#!/bin/bash

#  set cli mode to partial
export AWS_CLI_AUTO_PROMPT=on-partial

StackName=user-bob

# create cloudformation stack
echo "creating user bob"
aws cloudformation create-stack --stack-name $StackName \
    --template-body file://01_DEMOSETUP/bob.yaml \
    --parameters ParameterKey=bobpassword,ParameterValue=boBpassword*1 \
    --capabilities CAPABILITY_NAMED_IAM

while  [ "$(aws cloudformation describe-stacks --stack-name $StackName --query Stacks[0].StackStatus --output text)" != "CREATE_COMPLETE" ]; do 
  aws cloudformation describe-stacks --stack-name $StackName --query Stacks[0].StackStatus --output text
  sleep 1
done

# find Master Account ID
MasterAccountID=$(aws sts get-caller-identity --query Account --output text)
  
# creating 3 S3 buckets and IAM Role to assume by Master Account in prod account
echo ""
echo "creating 3 S3 buckets and IAM Role in PROD Account"

S3Buckets=Buckets
aws cloudformation create-stack \
    --stack-name $S3Buckets \
    --template-body file://01_DEMOSETUP/prod_bucketsandrole.yaml \
    --profile prod \
    --parameters ParameterKey=AccountToTrust,ParameterValue=$MasterAccountID \
    --capabilities CAPABILITY_IAM
    
while  [ "$(aws cloudformation describe-stacks --stack-name $S3Buckets --query Stacks[0].StackStatus --profile prod --output text)" != "CREATE_COMPLETE" ]; do 
  aws cloudformation describe-stacks --stack-name $S3Buckets --query Stacks[0].StackStatus --profile prod --output text
  sleep 1
done    
# find Prod Account ID
echo ""
PRODAccountID=$(aws sts get-caller-identity --profile prod --query Account --output text)  
echo "Production Account ID = $PRODAccountID"
 
# create bucket URLs" 
echo ""
bucket1=$(aws s3 ls --profile prod | cut -f3 -d " " | awk 'NR==1')
bucket2=$(aws s3 ls --profile prod | cut -f3 -d " " | awk 'NR==2')
bucket3=$(aws s3 ls --profile prod | cut -f3 -d " " | awk 'NR==3')

echo "bucket 1 url = https://console.aws.amazon.com/s3/buckets/$bucket1?region=us-east-1&tab=objects"
echo "bucket 2 url = https://console.aws.amazon.com/s3/buckets/$bucket2?region=us-east-1&tab=objects"
echo "bucket 3 url = https://console.aws.amazon.com/s3/buckets/$bucket3?region=us-east-1&tab=objects"
echo ""

# find Account Aliases and generate signin URL, print username and password
AccountAliases=$(aws iam list-account-aliases --query AccountAliases --output text)
echo "user url to sign in as bob user https://$AccountAliases.signin.aws.amazon.com/console/"
BobUserName=$(aws iam list-users --query 'Users[?contains(UserName, `bob`) == `true`]|[0].UserName' --output text)  
echo "username = $BobUserName"
echo "password = boBpassword*1"
echo ""

# find Master Account Canonical ID
MasterAccountCanonicalID=$(aws s3api list-buckets --query Owner.ID --output text)
echo "Master Account Canonical_ID = $MasterAccountCanonicalID"
echo ""

# find IAM Role name to assume by bob user in Master Account
IAMRoleName=$(aws iam list-roles --profile prod --query 'Roles[?contains(RoleName, `Buckets`) == `true`]|[0].RoleName' --output text)
echo "IAM Role Name = $IAMRoleName"
echo ""

