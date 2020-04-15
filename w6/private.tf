resource "aws_subnet" "private_sb" {
  vpc_id = aws_vpc.vpc_main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1e"

  tags = {
    Name = "private"
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
  iam_instance_profile = aws_iam_instance_profile.aws_s3_profile.id
  tags = {
    Name = "private"
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo su
              sudo yum -y install postgresql
              sudo aws s3 cp s3://aishchenko-test/persist3-0.0.1-SNAPSHOT.jar .
              sudo yum install java-1.8.0-openjdk -y
              sudo yum remove java-1.7.0-openjdk -y
              export RDS_HOST="${aws_db_instance.mydb1.address}"
              sudo java -jar persist3-0.0.1-SNAPSHOT.jar
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

//postgres
resource "aws_db_instance" "mydb1" {
  allocated_storage        = 20 # gigabytes
  storage_type             = "gp2"
  engine                   = "postgres"
  engine_version           = "9.5.4"
//  identifier               = "EduLohikaTrainingAwsRds"
  instance_class           = "db.t2.micro"
  name                     = "EduLohikaTrainingAwsRds"
  username                 = "rootuser"
  password                 = "rootuser"
  vpc_security_group_ids = [
    aws_security_group.private-sg.id]
  db_subnet_group_name = aws_db_subnet_group.subnet_group.name
  port                     = 5432
  publicly_accessible      = true
  skip_final_snapshot      = true
}

resource "aws_db_subnet_group" "subnet_group" {
  name       = "main"
  subnet_ids = ["${aws_subnet.private_sb.id}", "${aws_subnet.public_sb.id}"]

  tags = {
    Name = "My DB subnet group"
  }
}

//aws s3 profile
resource "aws_iam_role_policy" "aws_s3_policy" {
  name = "aws_s3_policy"
  role = aws_iam_role.aws_s3_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
       "s3:*",
        "sqs:SendMessage",
         "sqs:ReceiveMessage"],
      "Resource": [
        "arn:aws:s3:::aishchenko-test/*",
        "arn:aws:sqs:*:*:*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "aws_s3_profile" {
  name = "aws_s3_profile"
  role = "aws_s3_role"
}

resource "aws_iam_role" "aws_s3_role" {
  name = "aws_s3_role"
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
