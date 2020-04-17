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
