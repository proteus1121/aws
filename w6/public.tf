resource "aws_subnet" "public_sb" {
  vpc_id = aws_vpc.vpc_main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public"
  }
}

resource "aws_launch_configuration" "my-public-launch-config" {
  image_id = "ami-0ff8a91507f77f867"
  instance_type = "t2.micro"
  security_groups = [
    aws_security_group.public-sg.id]
  key_name = "testkey"
  iam_instance_profile = aws_iam_instance_profile.aws_dynamodb_profile.id

  user_data = <<-EOF
              #!/bin/bash
              sudo su
              aws s3 cp s3://aishchenko-test/calc-0.0.1-SNAPSHOT.jar .
              sudo yum install java-1.8.0-openjdk -y
              sudo yum remove java-1.7.0-openjdk -y
              sudo java -jar calc-0.0.1-SNAPSHOT.jar
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "autoscalling-group" {
//  availability_zones = [
//    "us-east-1a"]
  vpc_zone_identifier = [aws_subnet.public_sb.id]
  launch_configuration = aws_launch_configuration.my-public-launch-config.name
  load_balancers = [aws_elb.test_lb.id]
  min_size = 2
  max_size = 2
}

resource "aws_elb" "test_lb" {
  name               = "test-lb"

  security_groups    = [aws_security_group.public-sg.id]
  subnets            = [aws_subnet.public_sb.id]
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/health"
    interval            = 30
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc_main.id

  tags = {
    Name = "main"
  }
}

resource "aws_route_table" "r" {
  vpc_id = aws_vpc.vpc_main.id

  route {
    cidr_block        = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_sb.id
  route_table_id = aws_route_table.r.id
}

resource "aws_default_route_table" "vpc_default_r" {
  default_route_table_id = aws_vpc.vpc_main.default_route_table_id

  route {
    cidr_block        = "0.0.0.0/0"
    instance_id = aws_instance.bastion.id
  }
}

resource "aws_security_group" "public-sg" {
  vpc_id = aws_vpc.vpc_main.id
  name = "public-sg"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  ingress {
    //http
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  ingress {
    //ssh
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}

// dynamo db
resource "aws_dynamodb_table" "example" {
  name = "edu-lohika-training-aws-dynamodb"
  hash_key = "UserName"
//  range_key = "password"
  billing_mode = "PAY_PER_REQUEST"

  server_side_encryption {
    enabled = true
  }
  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "UserName"
    type = "S"
  }

  ttl {
    enabled = true
    attribute_name = "expires"
  }
}

//aws + dynamodb profile
resource "aws_iam_role_policy" "aws_dynamodb_policy" {
  name = "web_iam_role_policy"
  role = aws_iam_role.aws_dynamodb_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
       "s3:*",
        "dynamodb:*",
        "SNS:*"],
      "Resource": [
        "arn:aws:s3:::aishchenko-test/*",
        "arn:aws:dynamodb:us-east-1:*:table/edu-lohika-training-aws-dynamodb",
        "${aws_sns_topic.user_updates.arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "aws_dynamodb_profile" {
  name = "aws_dynamodb_profile"
  role = "aws_dynamodb_role"
}

resource "aws_iam_role" "aws_dynamodb_role" {
  name = "aws_dynamodb_role"
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
