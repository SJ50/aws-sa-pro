#!/bin/bash

#  set cli mode to partial
export AWS_CLI_AUTO_PROMPT=on-partial

# find Web A Subnet ID
nondefault_VPC_ID=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=false --query Vpcs[].VpcId --profile prod --output text)
WebASubnetID=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$nondefault_VPC_ID Name=tag:Name,Values=sn-web-A --query Subnets[].SubnetId --output text)

# create Security Group in PROD to launch Instance
SG_ID=$(aws ec2 create-security-group --vpc-id $nondefault_VPC_ID --group-name http  --description 'allow inbound http' --output text --profile prod)
# allow http from anywhere in Security Group
aws ec2 authorize-security-group-ingress --group-id $SG_ID --ip-permissions FromPort=80,ToPort=80,IpProtocol=tcp,IpRanges='[{CidrIp=0.0.0.0/0}]',Ipv6Ranges='[{CidrIpv6=::/0}]' --profile prod

EC2_Instance_ID=$(aws ec2 run-instances --image-id resolve:ssm:/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 \
        --instance-type t2.micro \
        --count 1 \
        --subnet-id $WebASubnetID \
        --security-group-ids $SG_ID \
        --user-data file://01_DEMOSETUP/in_prod_account_in_part_2/userdata.txt \
        --query Instances[].InstanceId \
        --output text \
        --profile prod)

while [ "$(aws ec2 describe-instances --instance-ids $EC2_Instance_ID --query Reservations[].Instances[].State[].Code --output text --profile prod)" != 16 ]; do
        aws ec2 describe-instances --instance-ids $EC2_Instance_ID --query Reservations[].Instances[].State[].Name --output text --profile prod
        sleep 1
done       

EC2_Public_IPv4=$(aws ec2 describe-instances --instance-ids $EC2_Instance_ID --query Reservations[].Instances[].PublicIpAddress --output text --profile prod)

echo "Public IPv4 of EC2 Instace = $EC2_Public_IPv4"

echo "Follow Part-2 of tutorial from 10:00"
