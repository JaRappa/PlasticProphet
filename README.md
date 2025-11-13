# PlasticProphet

Helps find the best credit card for you to use at any given moment.

Visit our website at https://plasticprophet.com

## 📱 iOS App

Native SwiftUI app with AWS Cognito authentication using OAuth 2.0 + PKCE for secure user management.

### Features
- Secure sign up and sign in with AWS Cognito
- User profile management
- Credit card recommendation engine
- Digital wallet integration

## 🔧 Backend Infrastructure

### AWS Lambda Functions
Lambda functions for user authentication and profile management. See **[`/lambda/README.md`](./lambda/README.md)** for deployment instructions.

- **PostConfirmationTrigger** - Automatically creates user profiles in PostgreSQL after email confirmation
- **GetProfileAPI** - REST API endpoint for retrieving user profile data

### AWS Services Used
- **Cognito** - User authentication and session management
- **API Gateway** - REST API endpoints with Cognito authorization
- **Lambda** - Serverless functions for business logic
- **RDS PostgreSQL** - User profile and application data storage

## 📚 Documentation

- [`/lambda/README.md`](./lambda/README.md) - Lambda function deployment guide
- [`/docs/AWS_COGNITO_SETUP.md`](./docs/AWS_COGNITO_SETUP.md) - Cognito configuration
- [`OAUTH2_IMPLEMENTATION.md`](./OAUTH2_IMPLEMENTATION.md) - OAuth 2.0 implementation details
- [`OAUTH2_QUICKSTART.md`](./OAUTH2_QUICKSTART.md) - Quick start guide

## 🚀 Getting Started

### Prerequisites
- Xcode 15+
- iOS 17+
- AWS account with Cognito, Lambda, RDS, and API Gateway configured

### Running the iOS App
1. Open `PlasticProphet.xcodeproj` in Xcode
2. Update `CognitoConfig.swift` with your AWS credentials
3. Build and run on simulator or device

### Deploying Backend
See [`/lambda/README.md`](./lambda/README.md) for complete deployment instructions.

## 🌐 Website

Static website hosted at https://plasticprophet.com

Source code in `/website/` directory.
