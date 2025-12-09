<div align="center">
  <img src="website/images/tpplogo.png" alt="Plastic Prophet Logo" width="120" height="120" />

  # Plastic Prophet

  **Smarter Credit Card Picks, Automatically**

  [![Platform](https://img.shields.io/badge/Platform-iOS%2017+-blue?style=for-the-badge&logo=apple)](https://developer.apple.com/ios/)
  [![Swift](https://img.shields.io/badge/Swift-5.9+-orange?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org/)
  [![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-blue?style=for-the-badge&logo=swift)](https://developer.apple.com/xcode/swiftui/)
  [![AWS](https://img.shields.io/badge/AWS-Cognito%20|%20Lambda%20|%20RDS-orange?style=for-the-badge&logo=amazonaws)](https://aws.amazon.com/)
  [![License](https://img.shields.io/badge/License-Proprietary-red?style=for-the-badge)]

  *Maximize your credit card rewards with intelligent, location-aware recommendations*

  [🌐 Website](https://plasticprophet.com) • [📱 App Store](#) • [📖 Documentation](https://plasticprophet.com/guide.html)

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
- [Tech Stack](#-tech-stack)
- [Architecture](#-architecture)
- [Getting Started](#-getting-started)
- [Project Structure](#-project-structure)
- [API Documentation](#-api-documentation)
- [Documentation](#-documentation)
- [Contributing](#-contributing)
- [Team](#-team)
- [License](#-license)

---

## 🎯 Overview

**Plastic Prophet** is a native iOS application that helps users maximize their credit card rewards by providing intelligent, real-time recommendations based on merchant categories, spending patterns, and location context.

### The Problem
Consumers often carry multiple credit cards with different reward structures, but struggle to remember which card offers the best rewards for each purchase. This leads to lost rewards and suboptimal spending.

### The Solution
Plastic Prophet analyzes your credit card portfolio and automatically recommends the optimal card to use at any given moment, ensuring you never miss out on rewards points, cash back, or other benefits.

---

## ✨ Key Features

<table>
<tr>
<td width="50%">

### 🏦 Smart Card Selection
- Add cards via camera scan, search, or manual entry
- Automatic network detection (Visa, Mastercard, Amex, Discover)
- Privacy-first: No sensitive card data stored

</td>
<td width="50%">

### 🎯 Intelligent Recommendations
- Location-aware merchant detection
- Category-based reward optimization
- Personalized spending insights

</td>
</tr>
<tr>
<td width="50%">

### 🔐 Enterprise-Grade Security
- OAuth 2.0 + PKCE authentication flow
- AWS Cognito secure user management
- No password or card data stored in app

</td>
<td width="50%">

### 📊 User Analytics
- Spending category breakdown
- Rewards earned tracking
- Personalized optimization tips

</td>
</tr>
</table>

---

## 🛠 Tech Stack

### Frontend (iOS)

| Technology | Purpose |
|------------|---------|
| **SwiftUI 5.0** | Modern declarative UI framework |
| **Swift 5.9+** | Primary programming language |
| **ASWebAuthenticationSession** | Secure OAuth browser authentication |
| **CoreLocation** | Location-based recommendations |
| **AVFoundation** | Card scanning via camera |

### Backend (AWS)

| Service | Purpose |
|---------|---------|
| **AWS Cognito** | User authentication & session management |
| **AWS Lambda (Python 3.11)** | Serverless business logic |
| **API Gateway** | REST API with Cognito authorization |
| **RDS PostgreSQL** | User profiles & application data |
| **RDS Proxy** | Connection pooling & failover |
| **CloudWatch** | Logging & monitoring |

### Security

| Feature | Implementation |
|---------|----------------|
| **OAuth 2.0 + PKCE** | Industry-standard secure authentication |
| **JWT Tokens** | Stateless API authorization |
| **VPC Security Groups** | Network isolation for database |
| **IAM Roles** | Least-privilege Lambda execution |

---

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                           PRESENTATION LAYER                        │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │                    iOS App (SwiftUI)                           │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │ │
│  │  │ My Cards │  │  Cards   │  │ Profile  │  │   Settings   │   │ │
│  │  │   View   │  │ Selection│  │   View   │  │     View     │   │ │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────────┘   │ │
│  └────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    ▼                               ▼
┌─────────────────────────────┐   ┌─────────────────────────────────┐
│     AWS COGNITO             │   │         API GATEWAY             │
│  ┌───────────────────────┐  │   │  ┌───────────────────────────┐  │
│  │  User Pool            │  │   │  │  REST API                 │  │
│  │  • OAuth 2.0 + PKCE   │  │   │  │  • Cognito Authorizer     │  │
│  │  • JWT Tokens         │  │   │  │  • CORS Enabled           │  │
│  │  • Hosted UI          │  │   │  │  • /profile endpoint      │  │
│  └───────────────────────┘  │   │  └───────────────────────────┘  │
└─────────────────────────────┘   └─────────────────────────────────┘
              │                                     │
              │ Post-Confirmation                   │ GET /profile
              │ Trigger                             │
              ▼                                     ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         AWS LAMBDA                                  │
│  ┌─────────────────────────┐    ┌─────────────────────────────┐    │
│  │ PostConfirmationTrigger │    │     GetProfileAPI           │    │
│  │ • Creates user profile  │    │ • Retrieves user data       │    │
│  │ • Python 3.11           │    │ • Python 3.11               │    │
│  └─────────────────────────┘    └─────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         DATA LAYER                                  │
│  ┌─────────────────────────┐    ┌─────────────────────────────┐    │
│  │      RDS Proxy          │───▶│   RDS PostgreSQL            │    │
│  │ • Connection pooling    │    │ • User profiles             │    │
│  │ • Failover handling     │    │ • Card selections           │    │
│  └─────────────────────────┘    └─────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🚀 Getting Started

### Prerequisites

- **Xcode 15+** with iOS 17 SDK
- **iOS 17+** device or simulator
- **AWS Account** with the following services configured:
  - Cognito User Pool
  - API Gateway
  - Lambda
  - RDS PostgreSQL

### iOS App Setup

```bash
# 1. Clone the repository
git clone https://github.com/JaRappa/PlasticProphet.git
cd PlasticProphet

# 2. Open in Xcode
open PlasticProphet.xcodeproj

# 3. Configure AWS credentials
# Edit PlasticProphet/CognitoConfig.swift with your AWS settings:
#   - User Pool ID
#   - Client ID
#   - Region
#   - Hosted UI Domain

# 4. Build and run
# Select your target device/simulator and press ⌘R
```

### Backend Deployment

```bash
# Navigate to lambda directory
cd lambda

# Follow the comprehensive deployment guide
# See lambda/README.md for step-by-step instructions
./deploy.sh
```

For detailed deployment instructions, see [`/lambda/README.md`](./lambda/README.md).

---

## 📁 Project Structure

```
PlasticProphet/
├── 📱 PlasticProphet/              # iOS App Source Code
│   ├── PlasticProphetApp.swift     # App entry point
│   ├── AppState.swift              # Global app state management
│   ├── Models.swift                # Data models (Card, Recommendation)
│   ├── Views/
│   │   ├── ContentView.swift       # Root navigation controller
│   │   ├── MainAppView.swift       # Main tab bar interface
│   │   ├── WalletView.swift        # Card list & selection interface
│   │   ├── CardSelectionView.swift # Card search & selection
│   │   ├── ProfileView.swift       # User profile
│   │   ├── SettingsView.swift      # App settings
│   │   └── OnboardingFlowView.swift# New user onboarding
│   ├── Auth/
│   │   ├── CognitoAuthServiceNoSDK.swift # OAuth 2.0 + PKCE implementation
│   │   ├── CognitoConfig.swift     # AWS configuration
│   │   ├── CognitoVerificationView.swift
│   │   └── AuthenticationViews.swift
│   ├── Services/
│   │   ├── APIService.swift        # API client
│   │   └── PermissionManager.swift # Camera/location permissions
│   └── Assets.xcassets/            # Images, colors, icons
│
├── 🧪 PlasticProphetTests/         # Unit Tests
├── 🧪 PlasticProphetUITests/       # UI Tests
│
├── ⚡ lambda/                       # AWS Lambda Functions
│   ├── PostConfirmationTrigger/    # Cognito post-confirmation hook
│   ├── GetProfileAPI/              # Profile retrieval endpoint
│   ├── HealthAPI/                  # Health check endpoint
│   ├── deploy.sh                   # Deployment script
│   ├── database_migration.sql      # Database schema
│   └── README.md                   # Deployment guide
│
├── 🌐 website/                      # Marketing Website
│   ├── index.html                  # Landing page
│   ├── privacy.html                # Privacy policy
│   └── images/                     # Website assets
│
├── 📚 docs/                         # Additional Documentation
│   ├── AWS_COGNITO_SETUP.md        # Cognito configuration guide
│   ├── LAMBDA_DEPLOYMENT_CONSOLE_GUIDE.md
│   ├── LogicalView.md              # Architecture logical view
│   ├── PhysicalView.md             # Deployment architecture
│   └── ProcessGeofenceRecomendation.md
│
├── OAUTH2_IMPLEMENTATION.md        # OAuth 2.0 + PKCE details
├── OAUTH2_QUICKSTART.md            # Quick start guide
└── README.md                       # This file
```

---

## 📡 API Documentation

### Authentication Flow

1. **User taps "Sign In"** → Opens Cognito Hosted UI via `ASWebAuthenticationSession`
2. **User authenticates** → Cognito returns authorization code
3. **App exchanges code** → Receives JWT tokens (access, ID, refresh)
4. **API calls include** → `Authorization: Bearer <access_token>`

### REST Endpoints

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| `GET` | `/profile` | Retrieve user profile | Cognito JWT |
| `OPTIONS` | `/profile` | CORS preflight | None |

### Response Format

```json
{
  "success": true,
  "data": {
    "user_id": "uuid",
    "first_name": "John",
    "last_name": "Doe",
    "email": "john@example.com",
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

---

## 📖 Documentation

| Document | Description |
|----------|-------------|
| [`/lambda/README.md`](./lambda/README.md) | Complete Lambda deployment guide |
| [`/docs/AWS_COGNITO_SETUP.md`](./docs/AWS_COGNITO_SETUP.md) | Cognito User Pool configuration |
| [`OAUTH2_IMPLEMENTATION.md`](./OAUTH2_IMPLEMENTATION.md) | OAuth 2.0 + PKCE technical details |
| [`OAUTH2_QUICKSTART.md`](./OAUTH2_QUICKSTART.md) | Quick start for OAuth setup |
| [`/docs/LogicalView.md`](./docs/LogicalView.md) | System logical architecture |
| [`/docs/PhysicalView.md`](./docs/PhysicalView.md) | Deployment architecture |

---

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Code Style

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use SwiftLint for code style enforcement
- Write meaningful commit messages
- Include unit tests for new features

---

## 👥 Team

|| Contributors ||
|-|-------------|-|
|| [@JaRappa](https://github.com/JaRappa) |  |
|| [@CarolineZanuto](https://github.com/carolinezanuto) |  |
|| [@AGjivovich](https://github.com/agjivovich) |  |
|| [@DanRamos04](https://github.com/danramos04) |  |
|| [@JohnKapiti](https://github.com/JohnKapiti) |  |


---

## 📄 License

This project is proprietary software. All rights reserved.

---

<div align="center">

**[⬆ Back to Top](#plastic-prophet)**

*Built with ❤️ using SwiftUI and AWS*

</div>
