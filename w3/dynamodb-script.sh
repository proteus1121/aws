aws dynamodb put-item --table-name users --item "{\"userId\":{\"S\":\"1\"},\"password\" : {\"S\": \"123456\"}}" --region us-east-1
aws dynamodb scan --table-name users --region us-east-1
