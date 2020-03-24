provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "vpc_main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_sb" {
  vpc_id     = aws_vpc.vpc_main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "public"
  }
}

resource "aws_subnet" "private_sb" {
  vpc_id     = aws_vpc.vpc_main.id
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

resource "aws_security_group" "my-asg-sg" {
  vpc_id = aws_vpc.vpc_main.id
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


resource "aws_instance" "public_instance" {
  ami = "ami-0ff8a91507f77f867"
  instance_type = "t2.micro"
  key_name = "testkey"
  security_groups = [
    aws_security_group.my-asg-sg.id]
  subnet_id     = aws_subnet.public_sb.id
  availability_zone = "us-east-1a"
  tags = {
    Name = "public"
  }
}

resource "aws_instance" "private_instance" {
  ami = "ami-0ff8a91507f77f867"
  instance_type = "t2.micro"
  key_name = "testkey"
  security_groups = [
    aws_vpc.vpc_main.default_security_group_id]
  subnet_id     = aws_subnet.private_sb.id
  availability_zone = "us-east-1e"
  tags = {
    Name = "private"
  }
}
