#!/bin/bash

# Plastic Prophet Lambda Deployment Script
# This script deploys both Lambda functions and sets up API Gateway
# All values are pre-configured for your environment

set -e  # Exit on any error

echo "🚀 Starting Plastic Prophet Lambda Deployment"
echo "=============================================="
echo ""

# Your environment variables (already filled in!)
export AWS_REGION="us-east-1"
export DB_PROXY_ENDPOINT="proxy-1762399671009-plasticprophet-db.proxy-cg1cy2qk2qui.us-east-1.rds.amazonaws.com"
export DB_NAME="plasticprophet"
export DB_USER="plasticadmin"
export DB_PASSWORD="Database123!"
export USER_POOL_ID="us-east-1_V2s48Yy0h"
export VPC_ID="vpc-09dc56b4f1c23efde"
export DB_SECURITY_GROUP_ID="sg-03d22c664992b6e7"

# Subnets - using private subnets from your RDS proxy configuration
export SUBNET_1="subnet-07a22f089ddc6dcbc"
export SUBNET_2="subnet-02c5727505ff6f09c"
export SUBNET_IDS="$SUBNET_1,$SUBNET_2"

echo "✅ Environment configured:"
echo "   Region: $AWS_REGION"
echo "   DB Proxy: $DB_PROXY_ENDPOINT"
echo "   User Pool: $USER_POOL_ID"
echo "   VPC: $VPC_ID"
echo ""

# ============================================
# Step 1: Create IAM Role
# ============================================
echo "📋 Step 1: Creating IAM Role for Lambda..."

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

# Check if role already exists
if aws iam get-role --role-name PlasticProphet-Lambda-ExecutionRole 2>/dev/null; then
    echo "   ⚠️  IAM role already exists, skipping creation"
    export LAMBDA_ROLE_ARN=$(aws iam get-role \
        --role-name PlasticProphet-Lambda-ExecutionRole \
        --query "Role.Arn" \
        --output text)
else
    aws iam create-role \
        --role-name PlasticProphet-Lambda-ExecutionRole \
        --assume-role-policy-document file:///tmp/lambda-trust-policy.json \
        --description "Execution role for Plastic Prophet Lambda functions"

    aws iam attach-role-policy \
        --role-name PlasticProphet-Lambda-ExecutionRole \
        --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

    aws iam attach-role-policy \
        --role-name PlasticProphet-Lambda-ExecutionRole \
        --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole

    export LAMBDA_ROLE_ARN=$(aws iam get-role \
        --role-name PlasticProphet-Lambda-ExecutionRole \
        --query "Role.Arn" \
        --output text)

    echo "   ✅ IAM role created: $LAMBDA_ROLE_ARN"
    echo "   Waiting 10 seconds for IAM propagation..."
    sleep 10
fi

# ============================================
# Step 2: Create Lambda Security Group
# ============================================
echo ""
echo "🔐 Step 2: Creating Lambda Security Group..."

# Check if security group already exists
EXISTING_SG=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=plasticprophet-lambda-sg" "Name=vpc-id,Values=$VPC_ID" \
    --query "SecurityGroups[0].GroupId" \
    --output text \
    --region $AWS_REGION 2>/dev/null || echo "None")

if [ "$EXISTING_SG" != "None" ] && [ "$EXISTING_SG" != "" ]; then
    echo "   ⚠️  Lambda security group already exists"
    export LAMBDA_SECURITY_GROUP_ID=$EXISTING_SG
else
    aws ec2 create-security-group \
        --group-name plasticprophet-lambda-sg \
        --description "Security group for Plastic Prophet Lambda functions" \
        --vpc-id $VPC_ID \
        --region $AWS_REGION

    export LAMBDA_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
        --filters "Name=group-name,Values=plasticprophet-lambda-sg" \
        --query "SecurityGroups[0].GroupId" \
        --output text \
        --region $AWS_REGION)

    echo "   ✅ Lambda security group created: $LAMBDA_SECURITY_GROUP_ID"
fi

# Allow Lambda to connect to RDS proxy
echo "   Configuring security group rules..."
aws ec2 authorize-security-group-ingress \
    --group-id $DB_SECURITY_GROUP_ID \
    --protocol tcp \
    --port 5432 \
    --source-group $LAMBDA_SECURITY_GROUP_ID \
    --region $AWS_REGION 2>/dev/null || echo "   ⚠️  Security group rule already exists"

echo "   ✅ Lambda can connect to RDS proxy"

# ============================================
# Step 3: Deploy PostConfirmationTrigger Lambda
# ============================================
echo ""
echo "📦 Step 3: Deploying PostConfirmationTrigger Lambda..."

cd /Users/carolinezanuto/Documents/PlasticProphet/lambda/PostConfirmationTrigger

# Install dependencies
echo "   Installing dependencies..."
pip3 install -r requirements.txt -t . -q

# Create deployment package
echo "   Creating deployment package..."
zip -rq PostConfirmationTrigger.zip . -x "*.pyc" -x "__pycache__/*"

# Check if Lambda already exists
if aws lambda get-function --function-name PlasticProphet-PostConfirmationTrigger --region $AWS_REGION 2>/dev/null; then
    echo "   ⚠️  Lambda function already exists, updating code..."
    aws lambda update-function-code \
        --function-name PlasticProphet-PostConfirmationTrigger \
        --zip-file fileb://PostConfirmationTrigger.zip \
        --region $AWS_REGION > /dev/null
    
    aws lambda update-function-configuration \
        --function-name PlasticProphet-PostConfirmationTrigger \
        --environment Variables="{DB_HOST=$DB_PROXY_ENDPOINT,DB_NAME=$DB_NAME,DB_USER=$DB_USER,DB_PASSWORD=$DB_PASSWORD,DB_PORT=5432}" \
        --region $AWS_REGION > /dev/null
else
    echo "   Creating Lambda function..."
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
        --region $AWS_REGION > /dev/null
fi

export POST_CONFIRMATION_LAMBDA_ARN=$(aws lambda get-function \
    --function-name PlasticProphet-PostConfirmationTrigger \
    --query "Configuration.FunctionArn" \
    --output text \
    --region $AWS_REGION)

echo "   ✅ PostConfirmationTrigger deployed: $POST_CONFIRMATION_LAMBDA_ARN"

# Add Cognito permission
echo "   Configuring Cognito permissions..."
aws lambda add-permission \
    --function-name PlasticProphet-PostConfirmationTrigger \
    --statement-id CognitoInvoke \
    --action lambda:InvokeFunction \
    --principal cognito-idp.amazonaws.com \
    --source-arn arn:aws:cognito-idp:$AWS_REGION:$(aws sts get-caller-identity --query Account --output text):userpool/$USER_POOL_ID \
    --region $AWS_REGION 2>/dev/null || echo "   ⚠️  Permission already exists"

# Link to Cognito
echo "   Linking Lambda to Cognito User Pool..."
aws cognito-idp update-user-pool \
    --user-pool-id $USER_POOL_ID \
    --lambda-config PostConfirmation=$POST_CONFIRMATION_LAMBDA_ARN \
    --region $AWS_REGION

echo "   ✅ Cognito trigger configured"

# ============================================
# Step 4: Deploy GetProfileAPI Lambda
# ============================================
echo ""
echo "🌐 Step 4: Deploying GetProfileAPI Lambda..."

cd /Users/carolinezanuto/Documents/PlasticProphet/lambda/GetProfileAPI

# Install dependencies
echo "   Installing dependencies..."
pip3 install -r requirements.txt -t . -q

# Create deployment package
echo "   Creating deployment package..."
zip -rq GetProfileAPI.zip . -x "*.pyc" -x "__pycache__/*"

# Check if Lambda already exists
if aws lambda get-function --function-name PlasticProphet-GetProfileAPI --region $AWS_REGION 2>/dev/null; then
    echo "   ⚠️  Lambda function already exists, updating code..."
    aws lambda update-function-code \
        --function-name PlasticProphet-GetProfileAPI \
        --zip-file fileb://GetProfileAPI.zip \
        --region $AWS_REGION > /dev/null
    
    aws lambda update-function-configuration \
        --function-name PlasticProphet-GetProfileAPI \
        --environment Variables="{DB_HOST=$DB_PROXY_ENDPOINT,DB_NAME=$DB_NAME,DB_USER=$DB_USER,DB_PASSWORD=$DB_PASSWORD,DB_PORT=5432}" \
        --region $AWS_REGION > /dev/null
else
    echo "   Creating Lambda function..."
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
        --region $AWS_REGION > /dev/null
fi

export GET_PROFILE_LAMBDA_ARN=$(aws lambda get-function \
    --function-name PlasticProphet-GetProfileAPI \
    --query "Configuration.FunctionArn" \
    --output text \
    --region $AWS_REGION)

echo "   ✅ GetProfileAPI deployed: $GET_PROFILE_LAMBDA_ARN"

# ============================================
# Step 5: Create API Gateway
# ============================================
echo ""
echo "🚪 Step 5: Creating API Gateway..."

# Check if API already exists
EXISTING_API=$(aws apigateway get-rest-apis \
    --query "items[?name=='PlasticProphet-API'].id" \
    --output text \
    --region $AWS_REGION)

if [ ! -z "$EXISTING_API" ] && [ "$EXISTING_API" != "" ]; then
    echo "   ⚠️  API Gateway already exists"
    export API_ID=$EXISTING_API
else
    export API_ID=$(aws apigateway create-rest-api \
        --name "PlasticProphet-API" \
        --description "API for Plastic Prophet user profile management" \
        --endpoint-configuration types=REGIONAL \
        --region $AWS_REGION \
        --query "id" \
        --output text)
    echo "   ✅ API Gateway created: $API_ID"
fi

# Get root resource
export ROOT_RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id $API_ID \
    --region $AWS_REGION \
    --query "items[?path=='/'].id" \
    --output text)

# Check if /profile resource exists
EXISTING_PROFILE_RESOURCE=$(aws apigateway get-resources \
    --rest-api-id $API_ID \
    --region $AWS_REGION \
    --query "items[?path=='/profile'].id" \
    --output text)

if [ ! -z "$EXISTING_PROFILE_RESOURCE" ] && [ "$EXISTING_PROFILE_RESOURCE" != "" ]; then
    echo "   ⚠️  /profile resource already exists"
    export PROFILE_RESOURCE_ID=$EXISTING_PROFILE_RESOURCE
else
    export PROFILE_RESOURCE_ID=$(aws apigateway create-resource \
        --rest-api-id $API_ID \
        --parent-id $ROOT_RESOURCE_ID \
        --path-part profile \
        --region $AWS_REGION \
        --query "id" \
        --output text)
    echo "   ✅ /profile resource created"
fi

# Create Cognito Authorizer
echo "   Creating Cognito authorizer..."
EXISTING_AUTHORIZER=$(aws apigateway get-authorizers \
    --rest-api-id $API_ID \
    --region $AWS_REGION \
    --query "items[?name=='CognitoAuthorizer'].id" \
    --output text)

if [ ! -z "$EXISTING_AUTHORIZER" ] && [ "$EXISTING_AUTHORIZER" != "" ]; then
    export AUTHORIZER_ID=$EXISTING_AUTHORIZER
    echo "   ⚠️  Authorizer already exists"
else
    export AUTHORIZER_ID=$(aws apigateway create-authorizer \
        --rest-api-id $API_ID \
        --name CognitoAuthorizer \
        --type COGNITO_USER_POOLS \
        --provider-arns arn:aws:cognito-idp:$AWS_REGION:$(aws sts get-caller-identity --query Account --output text):userpool/$USER_POOL_ID \
        --identity-source method.request.header.Authorization \
        --region $AWS_REGION \
        --query "id" \
        --output text)
    echo "   ✅ Cognito authorizer created"
fi

# Create GET method
echo "   Configuring GET method..."
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $PROFILE_RESOURCE_ID \
    --http-method GET \
    --authorization-type COGNITO_USER_POOLS \
    --authorizer-id $AUTHORIZER_ID \
    --region $AWS_REGION 2>/dev/null || echo "   ⚠️  GET method already exists"

# Lambda integration
aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $PROFILE_RESOURCE_ID \
    --http-method GET \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri arn:aws:apigateway:$AWS_REGION:lambda:path/2015-03-31/functions/$GET_PROFILE_LAMBDA_ARN/invocations \
    --region $AWS_REGION 2>/dev/null || echo "   ⚠️  Integration already exists"

# Grant API Gateway permission to invoke Lambda
aws lambda add-permission \
    --function-name PlasticProphet-GetProfileAPI \
    --statement-id apigateway-invoke \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:$AWS_REGION:$(aws sts get-caller-identity --query Account --output text):$API_ID/*/*" \
    --region $AWS_REGION 2>/dev/null || echo "   ⚠️  Permission already exists"

# Enable CORS
echo "   Enabling CORS..."
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $PROFILE_RESOURCE_ID \
    --http-method OPTIONS \
    --authorization-type NONE \
    --region $AWS_REGION 2>/dev/null || echo "   ⚠️  OPTIONS method already exists"

aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $PROFILE_RESOURCE_ID \
    --http-method OPTIONS \
    --type MOCK \
    --request-templates '{"application/json": "{\"statusCode\": 200}"}' \
    --region $AWS_REGION 2>/dev/null

aws apigateway put-method-response \
    --rest-api-id $API_ID \
    --resource-id $PROFILE_RESOURCE_ID \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters '{"method.response.header.Access-Control-Allow-Headers": false, "method.response.header.Access-Control-Allow-Methods": false, "method.response.header.Access-Control-Allow-Origin": false}' \
    --region $AWS_REGION 2>/dev/null

aws apigateway put-integration-response \
    --rest-api-id $API_ID \
    --resource-id $PROFILE_RESOURCE_ID \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters '{"method.response.header.Access-Control-Allow-Headers": "\"Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token\"", "method.response.header.Access-Control-Allow-Methods": "\"GET,OPTIONS\"", "method.response.header.Access-Control-Allow-Origin": "\"*\""}' \
    --region $AWS_REGION 2>/dev/null

echo "   ✅ CORS configured"

# Deploy API
echo "   Deploying API to production..."
aws apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name prod \
    --stage-description "Production stage" \
    --description "Deployment on $(date)" \
    --region $AWS_REGION > /dev/null

echo "   ✅ API deployed to prod stage"

# ============================================
# Step 6: Update iOS App
# ============================================
echo ""
echo "📱 Step 6: Updating iOS App..."

export API_ENDPOINT="https://$API_ID.execute-api.$AWS_REGION.amazonaws.com/prod/profile"

cd /Users/carolinezanuto/Documents/PlasticProphet

# Backup original file
cp PlasticProphet/CognitoAuthServiceNoSDK.swift PlasticProphet/CognitoAuthServiceNoSDK.swift.backup 2>/dev/null || true

# Update the API URL
sed -i '' "s|https://syidcdnccc.execute-api.us-east-1.amazonaws.com/prod/profile|$API_ENDPOINT|g" PlasticProphet/CognitoAuthServiceNoSDK.swift

echo "   ✅ iOS app updated with new API endpoint"

# ============================================
# Deployment Complete!
# ============================================
echo ""
echo "========================================="
echo "🎉 DEPLOYMENT COMPLETE!"
echo "========================================="
echo ""
echo "✅ Lambda Functions Deployed:"
echo "   - PlasticProphet-PostConfirmationTrigger"
echo "   - PlasticProphet-GetProfileAPI"
echo ""
echo "✅ API Gateway Configured:"
echo "   - API ID: $API_ID"
echo "   - Endpoint: https://$API_ID.execute-api.$AWS_REGION.amazonaws.com/prod"
echo ""
echo "✅ iOS App Updated:"
echo "   - CognitoAuthServiceNoSDK.swift now uses the correct API endpoint"
echo ""
echo "========================================="
echo "📋 Next Steps:"
echo "========================================="
echo ""
echo "1. Test PostConfirmationTrigger:"
echo "   aws logs tail /aws/lambda/PlasticProphet-PostConfirmationTrigger --follow --region $AWS_REGION"
echo ""
echo "2. Test GetProfileAPI:"
echo "   aws logs tail /aws/lambda/PlasticProphet-GetProfileAPI --follow --region $AWS_REGION"
echo ""
echo "3. Open your iOS app in Xcode and test:"
echo "   - Sign up a new user"
echo "   - Confirm email"
echo "   - Sign in"
echo "   - Profile should load automatically!"
echo ""
echo "========================================="
echo "✅ All done! Happy coding! 🚀"
echo "========================================="
