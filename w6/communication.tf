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
