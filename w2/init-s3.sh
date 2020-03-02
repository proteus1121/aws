aws s3 mb s3://aishchenko-test
aws s3api put-bucket-versioning --bucket aishchenko-test --versioning-configuration Status=Enabled
aws s3 cp image.png s3://aishchenko-test
