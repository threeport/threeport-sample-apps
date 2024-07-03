#!/bin/bash

cat > distilbert-secret-definition.yaml <<EOF
SecretDefinition:
  Name: aws-creds
  AwsAccountName: default-account
  Data:
    aws-region: "${AWS_DEFAULT_REGION}"
    aws-access-key-id: "${AWS_ACCESS_KEY_ID}"
    aws-secret-access-key: "${AWS_SECRET_ACCESS_KEY}"
EOF

