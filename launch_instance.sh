#!/bin/bash

# 🚀 Step 1: Launch EC2 Instance
echo "Launching EC2 instance..."
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id ami-09dc1ba68d413c979 \
    --instance-type r5.16xlarge \
    --key-name zcollester \
    --security-group-ids sg-0fa8768cfcfb31b88 \
    --subnet-id subnet-0714c0d08c1d7f796 \
    --block-device-mappings '[
        {"DeviceName": "/dev/sdf", "Ebs": {"VolumeSize": 500, "VolumeType": "gp3"}}
    ]' \
    --query "Instances[0].InstanceId" --output text)

echo "EC2 Instance launched with ID: $INSTANCE_ID"

# 🚀 Step 2: Wait for Instance to Initialize
echo "Waiting for instance to enter 'running' state..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# 🚀 Step 3: Retrieve Public IP Address
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query "Reservations[0].Instances[0].PublicIpAddress" --output text)

echo "Instance is now running!"
echo "Public IP Address: $PUBLIC_IP"

# 🚀 Step 4: Display SSH Connection Command
echo "To connect to your instance, use the following command:"
echo "ssh -i ~/.aws/zcollester.pem ec2-user@$PUBLIC_IP"

