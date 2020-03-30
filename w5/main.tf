provider "aws" {
  region = "us-east-1"
}

resource "aws_sns_topic" "user_updates" {
  name = "user-updates-topic"
}

resource "aws_sqs_queue" "user_updates_queue" {
  name = "user-updates-queue"
}

resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = aws_sns_topic.user_updates.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.user_updates_queue.arn
}

resource "aws_sns_topic_subscription" "sms_alerts_sub" {
  topic_arn = aws_sns_topic.user_updates.arn
  protocol = "sms"
  endpoint = "XXXXXXXX"
}
