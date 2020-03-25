provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "vpc_main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_sb" {
  vpc_id = aws_vpc.vpc_main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public"
  }
}

resource "aws_subnet" "private_sb" {
  vpc_id = aws_vpc.vpc_main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1e"

  tags = {
    Name = "private"
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
    //ssh
    from_port = 22
    protocol = "tcp"
    to_port = 22
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
}

resource "aws_instance" "public_instance" {
  ami = "ami-0ff8a91507f77f867"
  instance_type = "t2.micro"
  key_name = "testkey"
  security_groups = [
    aws_security_group.public-sg.id]
  subnet_id = aws_subnet.public_sb.id
  availability_zone = "us-east-1a"
  tags = {
    Name = "public"
  }
  iam_instance_profile = aws_iam_instance_profile.test_profile.id

  user_data = <<-EOF
              #!/bin/bash
              aws s3 cp s3://aishchenko-test/testkey.pem .
              sudo su
              yum -y update
              yum -y install httpd
              service httpd start
              chkconfig httpd on
              cd /var/www/html
              echo "<html><h1>This is WebServer from public subnet</h1></html>" > index.html
              EOF
}

resource "aws_security_group" "private-sg" {
  vpc_id = aws_vpc.vpc_main.id
  name = "private-sg"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
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

  ingress {
    //http
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  ingress {
    //icmp
    cidr_blocks = [
      "0.0.0.0/0"]
    protocol = "icmp"
    from_port = 8
    to_port = 8
  }
}

resource "aws_instance" "private_instance" {
  ami = "ami-0ff8a91507f77f867"
  instance_type = "t2.micro"
  key_name = "testkey"
  security_groups = [
    aws_security_group.private-sg.id]
  subnet_id = aws_subnet.private_sb.id
  availability_zone = "us-east-1e"
  tags = {
    Name = "private"
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo su
              yum -y update
              yum -y install httpd
              service httpd start
              chkconfig httpd on
              cd /var/www/html
              echo "<html><h1>This is WebServer from private subnet</h1></html>" > index.html
              EOF
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
       "s3:*" ],
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

resource "aws_instance" "nat_instance" {
  ami = "ami-00a9d4a05375b2763"
  instance_type = "t2.micro"
  security_groups = [
    aws_security_group.public-sg.id]
  subnet_id = aws_subnet.public_sb.id
  availability_zone = "us-east-1a"
  source_dest_check = false
  tags = {
    Name = "nat"
  }
}

resource "aws_default_route_table" "vpc_default_r" {
  default_route_table_id = aws_vpc.vpc_main.default_route_table_id

  route {
    cidr_block        = "0.0.0.0/0"
    instance_id = aws_instance.nat_instance.id
  }
}

resource "aws_lb_target_group" "bar" {
  name = "elb"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_main.id
  health_check {
    path = "/index.html"
    protocol = "http"
  }
}

resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.bar.arn
  target_id        = aws_instance.public_instance.id
}

resource "aws_lb_target_group_attachment" "test2" {
  target_group_arn = aws_lb_target_group.bar.arn
  target_id        = aws_instance.private_instance.id
}

resource "aws_lb" "test_lb" {
  name               = "test-lb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.public-sg.id]
  subnets            = [aws_subnet.public_sb.id, aws_subnet.private_sb.id]
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.test_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.bar.arn
  }
}
