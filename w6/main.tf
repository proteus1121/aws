provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "vpc_main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}

resource "aws_instance" "bastion" {
  ami = "ami-0ff8a91507f77f867"
  instance_type = "t2.micro"
  key_name = "testkey"
  security_groups = [
    aws_security_group.public-sg.id]
  subnet_id = aws_subnet.public_sb.id
  availability_zone = "us-east-1a"
  iam_instance_profile = aws_iam_instance_profile.aws_s3_profile.id
  source_dest_check = false
  tags = {
    Name = "bastion"
  }

  user_data = <<-EOF
              #!/bin/bash
              aws s3 cp s3://aishchenko-test/testkey.pem .
              EOF
}

resource "aws_sns_topic" "user_updates" {
  name = "edu-lohika-training-aws-sns-topic"
}

resource "aws_sqs_queue" "user_updates_queue" {
  name = "edu-lohika-training-aws-sqs-queue"
}

resource "aws_sqs_queue_policy" "test" {
  queue_url = aws_sqs_queue.user_updates_queue.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "First",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:*",
      "Resource": "${aws_sqs_queue.user_updates_queue.arn}"
    }
  ]
}
POLICY
}

resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = aws_sns_topic.user_updates.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.user_updates_queue.arn
}

//resource "aws_sns_topic_subscription" "sms_alerts_sub" {
//  topic_arn = aws_sns_topic.user_updates.arn
//  protocol = "sms"
//  endpoint = "XXXXXXXX"
//}

