#!/bin/bash

# Deploy MCCMatcherAPI Lambda Function
# This script creates a deployment package and updates/creates the Lambda function

set -e

echo "🚀 Deploying MCCMatcherAPI Lambda Function"
echo "==========================================="

# Configuration
FUNCTION_NAME="MCCMatcherAPI"
AWS_REGION="${AWS_REGION:-us-east-1}"
RUNTIME="python3.11"

# Get directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "📦 Creating deployment package..."

# Clean up any existing package
rm -rf package/
rm -f deployment.zip

# Create package directory
mkdir -p package

# Install dependencies
pip install -r requirements.txt -t package/ --quiet

# Copy Lambda function and MCC codes
cp lambda_function.py package/
cp mcc_codes.json package/

# Create zip file
cd package
zip -r ../deployment.zip . -x "*.pyc" -x "__pycache__/*" -x "*.dist-info/*" --quiet
cd ..

echo "✅ Created deployment.zip"

# Check if function exists
if aws lambda get-function --function-name "$FUNCTION_NAME" --region "$AWS_REGION" 2>/dev/null; then
    echo "📤 Updating existing Lambda function..."
    aws lambda update-function-code \
        --function-name "$FUNCTION_NAME" \
        --zip-file fileb://deployment.zip \
        --region "$AWS_REGION"
else
    echo "📤 Creating new Lambda function..."
    echo "⚠️  You need to create the Lambda function first in AWS Console"
    echo "   or provide a role ARN to create it via CLI."
    echo ""
    echo "   Manual steps:"
    echo "   1. Go to AWS Lambda Console"
    echo "   2. Create function: $FUNCTION_NAME"
    echo "   3. Runtime: Python 3.11"
    echo "   4. Upload deployment.zip"
    echo "   5. Set environment variable: OPENAI_API_KEY"
    echo ""
    echo "   OR run with LAMBDA_ROLE_ARN environment variable:"
    echo "   LAMBDA_ROLE_ARN=arn:aws:iam::xxx:role/xxx ./deploy.sh"
fi

# Clean up
rm -rf package/

echo ""
echo "✅ Deployment package ready!"
echo ""
echo "Your OpenAI API key has been configured in the deploy script."
echo "When deploying to an existing Lambda, it will be set automatically."
