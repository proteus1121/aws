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
        "sqs:*",
        "SNS:*"],
      "Resource": [
        "arn:aws:s3:::aishchenko-test/*",
        "arn:aws:sqs:*:*:*",
        "${aws_sns_topic.user_updates.arn}"
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
