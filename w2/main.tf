provider "aws" {
  region = "us-east-1"
}

resource "aws_launch_configuration" "my-test-launch-config" {
  image_id = "ami-0ff8a91507f77f867"
  instance_type = "t2.micro"
  security_groups = [
    aws_security_group.my-asg-sg.id]
  key_name = "testkey"
  iam_instance_profile = aws_iam_instance_profile.test_profile.id

  user_data = <<-EOF
              #!/bin/bash
              aws s3 cp s3://aishchenko-test/image.png .
              sudo yum install java-1.8.0-openjdk -y
              sudo yum remove java-1.7.0-openjdk -y
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  availability_zones = [
    "us-east-1a"]
  launch_configuration = aws_launch_configuration.my-test-launch-config.name
  min_size = 2
  max_size = 2
}

resource "aws_security_group" "my-asg-sg" {
  name = "my-asg-sg"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "inbound_ssh" {
  from_port = 22
  protocol = "tcp"
  security_group_id = aws_security_group.my-asg-sg.id
  to_port = 22
  type = "ingress"
  cidr_blocks = [
    "0.0.0.0/0"]
}

resource "aws_security_group_rule" "inbound_http" {
  from_port = 80
  protocol = "tcp"
  security_group_id = aws_security_group.my-asg-sg.id
  to_port = 80
  type = "ingress"
  cidr_blocks = [
    "0.0.0.0/0"]
}

resource "aws_security_group_rule" "inbound_https" {
  from_port = 443
  protocol = "tcp"
  security_group_id = aws_security_group.my-asg-sg.id
  to_port = 443
  type = "ingress"
  cidr_blocks = [
    "0.0.0.0/0"]
}

resource "aws_iam_role_policy" "bucket_policy" {
  name = "web_iam_role_policy"
  role = aws_iam_role.test_iam_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [ "s3:*" ],
      "Resource": [
        "arn:aws:s3:::aishchenko-test/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "test_profile" {
  name = "test_profile"
  role = "test_iam_role"
}

resource "aws_iam_role" "test_iam_role" {
  name = "test_iam_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
