# Lambda Functions Deployment Guide - Quick Start

## 📋 Overview

**You already have:** RDS database with proxy configured ✅

**What we'll deploy:**
1. **PostConfirmationTrigger Lambda** - Creates user profiles in PostgreSQL after Cognito email confirmation
2. **GetProfileAPI Lambda** - Retrieves user profiles (called by iOS app)
3. **API Gateway** - REST API with /profile endpoint

**Total Time:** ~20-30 minutes

---

## 🎯 Prerequisites

From your screenshot, I can see you have:
- ✅ RDS Proxy: `proxy-1762399671009-plasticprophet-db`
- ✅ Proxy Endpoint: `proxy-1762399671009-plasticprophet-db.<region>.rds.amazonaws.com`
- ✅ VPC Security Group: `sg-03d22c664992b6e7`
- ✅ Subnets configured

**You need to know:**
- [ ] Your AWS region (e.g., `us-east-1`)
- [ ] Your Cognito User Pool ID
- [ ] Database name (likely `plasticprophet`)
- [ ] Database username and password
- [ ] VPC ID where your RDS/proxy is located

---

## 🚀 Quick Setup - Environment Variables

First, set all your environment variables (this makes the rest easier):

```bash
# Replace these with your actual values
export AWS_REGION="us-east-1"  # Your AWS region
export DB_PROXY_ENDPOINT="proxy-1762399671009-plasticprophet-db.proxy-xxxxxx.us-east-1.rds.amazonaws.com"  # Get from RDS Proxy console
export DB_NAME="plasticprophet"  # Your database name
export DB_USER="your_db_username"  # Your database username
export DB_PASSWORD="your_db_password"  # Your database password
export USER_POOL_ID="us-east-1_xxxxxxxxx"  # Your Cognito User Pool ID
export VPC_ID="vpc-xxxxxx"  # Your VPC ID (where RDS proxy is)
export DB_SECURITY_GROUP_ID="sg-03d22c664992b6e7"  # From your screenshot

# Subnets - use the PRIVATE subnets from your screenshot (pick 2)
export SUBNET_1="subnet-07a22f089ddc6dcbc"  # First private subnet
export SUBNET_2="subnet-02c5727505ff6f09c"  # Second private subnet
export SUBNET_IDS="$SUBNET_1,$SUBNET_2"

# Verify everything is set
echo "Region: $AWS_REGION"
echo "DB Proxy: $DB_PROXY_ENDPOINT"
echo "User Pool: $USER_POOL_ID"
echo "Subnets: $SUBNET_IDS"
```

---

## 🔐 Step 1: Create IAM Role for Lambda

```bash
# Create trust policy
cat > /tmp/lambda-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create the IAM role
aws iam create-role \
    --role-name PlasticProphet-Lambda-ExecutionRole \
    --assume-role-policy-document file:///tmp/lambda-trust-policy.json \
    --description "Execution role for Plastic Prophet Lambda functions"

# Attach basic Lambda execution policy (for CloudWatch Logs)
aws iam attach-role-policy \
    --role-name PlasticProphet-Lambda-ExecutionRole \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Attach VPC execution policy (to access RDS in VPC)
aws iam attach-role-policy \
    --role-name PlasticProphet-Lambda-ExecutionRole \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole

# Get the role ARN
export LAMBDA_ROLE_ARN=$(aws iam get-role \
    --role-name PlasticProphet-Lambda-ExecutionRole \
    --query "Role.Arn" \
    --output text)

echo "✅ Lambda Role ARN: $LAMBDA_ROLE_ARN"

# Wait 10 seconds for IAM role to propagate
echo "Waiting for IAM role to propagate..."
sleep 10
```

---

## 🔧 Step 2: Create Lambda Security Group

```bash
# Create security group for Lambda functions
aws ec2 create-security-group \
    --group-name plasticprophet-lambda-sg \
    --description "Security group for Plastic Prophet Lambda functions" \
    --vpc-id $VPC_ID \
    --region $AWS_REGION

# Get Lambda security group ID
export LAMBDA_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=plasticprophet-lambda-sg" \
    --query "SecurityGroups[0].GroupId" \
    --output text \
    --region $AWS_REGION)

echo "✅ Lambda Security Group: $LAMBDA_SECURITY_GROUP_ID"

# Allow Lambda to connect to RDS proxy (port 5432)
aws ec2 authorize-security-group-ingress \
    --group-id $DB_SECURITY_GROUP_ID \
    --protocol tcp \
    --port 5432 \
    --source-group $LAMBDA_SECURITY_GROUP_ID \
    --region $AWS_REGION

echo "✅ Lambda can now connect to RDS proxy"
```

---

## 📦 Step 3: Deploy PostConfirmationTrigger Lambda

```bash
cd /Users/carolinezanuto/Documents/PlasticProphet/lambda/PostConfirmationTrigger

# Install dependencies
pip3 install -r requirements.txt -t .

# Create deployment package
zip -r PostConfirmationTrigger.zip . -x "*.pyc" -x "__pycache__/*"

# Create the Lambda function
aws lambda create-function \
    --function-name PlasticProphet-PostConfirmationTrigger \
    --runtime python3.11 \
    --role $LAMBDA_ROLE_ARN \
    --handler lambda_function.lambda_handler \
    --zip-file fileb://PostConfirmationTrigger.zip \
    --timeout 30 \
    --memory-size 256 \
    --vpc-config SubnetIds=$SUBNET_IDS,SecurityGroupIds=$LAMBDA_SECURITY_GROUP_ID \
    --environment Variables="{DB_HOST=$DB_PROXY_ENDPOINT,DB_NAME=$DB_NAME,DB_USER=$DB_USER,DB_PASSWORD=$DB_PASSWORD,DB_PORT=5432}" \
    --region $AWS_REGION

echo "✅ PostConfirmationTrigger Lambda created"

# Get Lambda ARN
export POST_CONFIRMATION_LAMBDA_ARN=$(aws lambda get-function \
    --function-name PlasticProphet-PostConfirmationTrigger \
    --query "Configuration.FunctionArn" \
    --output text \
    --region $AWS_REGION)

echo "Lambda ARN: $POST_CONFIRMATION_LAMBDA_ARN"

# Add permission for Cognito to invoke the Lambda
aws lambda add-permission \
    --function-name PlasticProphet-PostConfirmationTrigger \
    --statement-id CognitoInvoke \
    --action lambda:InvokeFunction \
    --principal cognito-idp.amazonaws.com \
    --source-arn arn:aws:cognito-idp:$AWS_REGION:$(aws sts get-caller-identity --query Account --output text):userpool/$USER_POOL_ID \
    --region $AWS_REGION

# Link Lambda to Cognito User Pool
aws cognito-idp update-user-pool \
    --user-pool-id $USER_POOL_ID \
    --lambda-config PostConfirmation=$POST_CONFIRMATION_LAMBDA_ARN \
    --region $AWS_REGION

echo "✅ Cognito trigger configured!"
```

---

## 🌐 Step 4: Deploy GetProfileAPI Lambda

```bash
cd /Users/carolinezanuto/Documents/PlasticProphet/lambda/GetProfileAPI

# Install dependencies
pip3 install -r requirements.txt -t .

# Create deployment package
zip -r GetProfileAPI.zip . -x "*.pyc" -x "__pycache__/*"

# Create the Lambda function
aws lambda create-function \
    --function-name PlasticProphet-GetProfileAPI \
    --runtime python3.11 \
    --role $LAMBDA_ROLE_ARN \
    --handler lambda_function.lambda_handler \
    --zip-file fileb://GetProfileAPI.zip \
    --timeout 30 \
    --memory-size 256 \
    --vpc-config SubnetIds=$SUBNET_IDS,SecurityGroupIds=$LAMBDA_SECURITY_GROUP_ID \
    --environment Variables="{DB_HOST=$DB_PROXY_ENDPOINT,DB_NAME=$DB_NAME,DB_USER=$DB_USER,DB_PASSWORD=$DB_PASSWORD,DB_PORT=5432}" \
    --region $AWS_REGION

echo "✅ GetProfileAPI Lambda created"

# Get Lambda ARN
export GET_PROFILE_LAMBDA_ARN=$(aws lambda get-function \
    --function-name PlasticProphet-GetProfileAPI \
    --query "Configuration.FunctionArn" \
    --output text \
    --region $AWS_REGION)

echo "Lambda ARN: $GET_PROFILE_LAMBDA_ARN"
```

---

## 🚪 Step 5: Create API Gateway

### 5.1 Create REST API

```bash
# Create API Gateway
export API_ID=$(aws apigateway create-rest-api \
    --name "PlasticProphet-API" \
    --description "API for Plastic Prophet user profile management" \
    --endpoint-configuration types=REGIONAL \
    --region $AWS_REGION \
    --query "id" \
    --output text)

echo "========================================="
echo "🎉 API Gateway ID: $API_ID"
echo "========================================="

# Get root resource ID
export ROOT_RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id $API_ID \
    --region $AWS_REGION \
    --query "items[?path=='/'].id" \
    --output text)

echo "Root Resource ID: $ROOT_RESOURCE_ID"
```

### 5.2 Create /profile Resource

```bash
# Create /profile resource
export PROFILE_RESOURCE_ID=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $ROOT_RESOURCE_ID \
    --path-part profile \
    --region $AWS_REGION \
    --query "id" \
    --output text)

echo "Profile Resource ID: $PROFILE_RESOURCE_ID"
```

### 5.3 Create Cognito Authorizer

```bash
# Create Cognito User Pool Authorizer
export AUTHORIZER_ID=$(aws apigateway create-authorizer \
    --rest-api-id $API_ID \
    --name CognitoAuthorizer \
    --type COGNITO_USER_POOLS \
    --provider-arns arn:aws:cognito-idp:$AWS_REGION:$(aws sts get-caller-identity --query Account --output text):userpool/$USER_POOL_ID \
    --identity-source method.request.header.Authorization \
    --region $AWS_REGION \
    --query "id" \
    --output text)

echo "Authorizer ID: $AUTHORIZER_ID"
```

### 5.4 Create GET Method on /profile

```bash
# Create GET method
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $PROFILE_RESOURCE_ID \
    --http-method GET \
    --authorization-type COGNITO_USER_POOLS \
    --authorizer-id $AUTHORIZER_ID \
    --region $AWS_REGION

# Set up Lambda integration
aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $PROFILE_RESOURCE_ID \
    --http-method GET \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri arn:aws:apigateway:$AWS_REGION:lambda:path/2015-03-31/functions/$GET_PROFILE_LAMBDA_ARN/invocations \
    --region $AWS_REGION

# Grant API Gateway permission to invoke Lambda
aws lambda add-permission \
    --function-name PlasticProphet-GetProfileAPI \
    --statement-id apigateway-invoke \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:$AWS_REGION:$(aws sts get-caller-identity --query Account --output text):$API_ID/*/*" \
    --region $AWS_REGION

echo "✅ GET /profile method configured"
```

### 5.5 Enable CORS

```bash
# Add OPTIONS method for CORS
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $PROFILE_RESOURCE_ID \
    --http-method OPTIONS \
    --authorization-type NONE \
    --region $AWS_REGION

# Mock integration for OPTIONS
aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $PROFILE_RESOURCE_ID \
    --http-method OPTIONS \
    --type MOCK \
    --request-templates '{"application/json": "{\"statusCode\": 200}"}' \
    --region $AWS_REGION

# OPTIONS method response
aws apigateway put-method-response \
    --rest-api-id $API_ID \
    --resource-id $PROFILE_RESOURCE_ID \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters '{"method.response.header.Access-Control-Allow-Headers": false, "method.response.header.Access-Control-Allow-Methods": false, "method.response.header.Access-Control-Allow-Origin": false}' \
    --region $AWS_REGION

# OPTIONS integration response
aws apigateway put-integration-response \
    --rest-api-id $API_ID \
    --resource-id $PROFILE_RESOURCE_ID \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters '{"method.response.header.Access-Control-Allow-Headers": "\"Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token\"", "method.response.header.Access-Control-Allow-Methods": "\"GET,OPTIONS\"", "method.response.header.Access-Control-Allow-Origin": "\"*\""}' \
    --region $AWS_REGION

echo "✅ CORS enabled"
```

### 5.6 Deploy API

```bash
# Deploy to production
aws apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name prod \
    --stage-description "Production stage" \
    --description "Initial deployment" \
    --region $AWS_REGION

echo ""
echo "========================================="
echo "🎉 DEPLOYMENT COMPLETE!"
echo "========================================="
echo ""
echo "API Endpoint:"
echo "https://$API_ID.execute-api.$AWS_REGION.amazonaws.com/prod"
echo ""
echo "Update your iOS app (CognitoAuthServiceNoSDK.swift line 363):"
echo "let apiURL = \"https://$API_ID.execute-api.$AWS_REGION.amazonaws.com/prod/profile\""
echo ""
echo "========================================="
```

---

## 📱 Step 6: Update Your iOS App

Update `CognitoAuthServiceNoSDK.swift`:

```bash
# This will show you the exact line to update
echo "Update line 363 in CognitoAuthServiceNoSDK.swift to:"
echo "let apiURL = \"https://$API_ID.execute-api.$AWS_REGION.amazonaws.com/prod/profile\""
```

Then manually edit the file or use this command:

```bash
cd /Users/carolinezanuto/Documents/PlasticProphet
# Backup first
cp PlasticProphet/CognitoAuthServiceNoSDK.swift PlasticProphet/CognitoAuthServiceNoSDK.swift.backup

# Update the API URL (replace with your actual API_ID and AWS_REGION)
sed -i '' "s|https://syidcdnccc.execute-api.us-east-1.amazonaws.com/prod/profile|https://$API_ID.execute-api.$AWS_REGION.amazonaws.com/prod/profile|g" PlasticProphet/CognitoAuthServiceNoSDK.swift

echo "✅ iOS app updated!"
```

---

## 🧪 Step 7: Test Everything

### Test the PostConfirmationTrigger

```bash
# Create a test user in Cognito and confirm their email
# Then check CloudWatch logs:
aws logs tail /aws/lambda/PlasticProphet-PostConfirmationTrigger --follow --region $AWS_REGION
```

### Test the GetProfileAPI

After signing in to your iOS app, you'll get an access token. Test the API:

```bash
# Replace with actual token from your app
export ACCESS_TOKEN="your-access-token-here"

curl -X GET \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  "https://$API_ID.execute-api.$AWS_REGION.amazonaws.com/prod/profile"

# Should return JSON with user profile
```

### View Logs

```bash
# PostConfirmationTrigger logs
aws logs tail /aws/lambda/PlasticProphet-PostConfirmationTrigger --follow --region $AWS_REGION

# GetProfileAPI logs  
aws logs tail /aws/lambda/PlasticProphet-GetProfileAPI --follow --region $AWS_REGION
```

---

## 🔄 Update Lambda Functions (After Code Changes)

```bash
# PostConfirmationTrigger
cd /Users/carolinezanuto/Documents/PlasticProphet/lambda/PostConfirmationTrigger
zip -r PostConfirmationTrigger.zip . -x "*.pyc" -x "__pycache__/*"
aws lambda update-function-code \
    --function-name PlasticProphet-PostConfirmationTrigger \
    --zip-file fileb://PostConfirmationTrigger.zip \
    --region $AWS_REGION

# GetProfileAPI
cd /Users/carolinezanuto/Documents/PlasticProphet/lambda/GetProfileAPI
zip -r GetProfileAPI.zip . -x "*.pyc" -x "__pycache__/*"
aws lambda update-function-code \
    --function-name PlasticProphet-GetProfileAPI \
    --zip-file fileb://GetProfileAPI.zip \
    --region $AWS_REGION
```

---

## ❗ Troubleshooting

### Lambda can't connect to database
- Verify Lambda is in the same VPC as RDS proxy
- Check security group allows Lambda SG → RDS proxy SG on port 5432
- Use the **RDS Proxy endpoint**, not the RDS instance endpoint

### API returns 401 Unauthorized
- Verify Cognito authorizer is configured correctly
- Check that Authorization header has valid Bearer token
- Ensure token is from the correct User Pool

### API returns 502 Bad Gateway
- Check Lambda logs for errors: `aws logs tail /aws/lambda/PlasticProphet-GetProfileAPI --follow`
- Verify environment variables are set correctly
- Check database credentials

### Cognito trigger doesn't fire
- Verify Lambda permission allows Cognito to invoke it
- Check Cognito User Pool Lambda configuration in AWS Console
- Look for errors in CloudWatch logs

---

## ✅ Deployment Checklist

- [ ] IAM role for Lambda created
- [ ] Lambda security group created and can access RDS proxy
- [ ] PostConfirmationTrigger Lambda deployed
- [ ] PostConfirmationTrigger linked to Cognito User Pool
- [ ] GetProfileAPI Lambda deployed
- [ ] API Gateway created with /profile endpoint
- [ ] Cognito authorizer configured
- [ ] CORS enabled
- [ ] API deployed to `prod` stage
- [ ] iOS app updated with new API endpoint
- [ ] Tested sign-up creates database entry
- [ ] Tested sign-in loads profile from database

**You're done! 🎉**
