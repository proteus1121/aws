provider "aws" {
  region = "us-east-1"
}

resource "aws_dynamodb_table" "example" {
  name = "users"
  hash_key = "userId"
  range_key = "password"
  billing_mode = "PAY_PER_REQUEST"

  server_side_encryption {
    enabled = true
  }
  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "userId"
    type = "S"
  }
  attribute {
    name = "password"
    type = "S"
  }

  ttl {
    enabled = true
    attribute_name = "expires"
  }
}

resource "aws_autoscaling_group" "example" {
  availability_zones = [
    "us-east-1a"]
  launch_configuration = aws_launch_configuration.my-test-launch-config.name
  min_size = 1
  max_size = 1
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
              aws s3 cp s3://aishchenko-test/dynamodb-script.sh .
              sudo sh ./dynamodb-script.sh
              sudo yum -y install postgresql
              aws s3 cp s3://aishchenko-test/rds-script.sql .
              PGPASSWORD=admin123 psql --host="${aws_db_instance.mydb1.address}" -U admin123 -d users -a -q -f rds-script.sql
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "mydb1" {
  allocated_storage        = 20 # gigabytes
  storage_type             = "gp2"
  engine                   = "postgres"
  engine_version           = "9.5.4"
  identifier               = "users"
  instance_class           = "db.t2.micro"
  name                     = "users"
  username                 = "admin123"
  password                 = "admin123"
  vpc_security_group_ids = [
    aws_security_group.my-asg-sg.id]
  port                     = 5432
  publicly_accessible      = true
  skip_final_snapshot      = true
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

resource "aws_security_group_rule" "inbound_db" {
  from_port = 5432
  protocol = "tcp"
  security_group_id = aws_security_group.my-asg-sg.id
  to_port = 5432
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
      "Action": [
       "s3:*",
        "dynamodb:*"],
      "Resource": [
        "arn:aws:s3:::aishchenko-test/*",
        "arn:aws:dynamodb:us-east-1:*:table/users"
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
