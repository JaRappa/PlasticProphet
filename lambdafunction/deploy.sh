#!/bin/bash

# Deploy Updated Lambda Function with Linux-compatible psycopg2
# Run this script to update your Lambda function

echo "Deploying Lambda function with fixed psycopg2..."

aws lambda update-function-code \
  --function-name MerchantResolverFn \
  --zip-file fileb://Lambda.zip \
  --region us-east-1

echo ""
echo "Deployment complete!"
echo ""
echo "Now test it with:"
echo "aws lambda invoke --function-name MerchantResolverFn --payload file://test_event.json response.json && cat response.json"
