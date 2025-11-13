// CognitoConfig.swift
// AWS Cognito authentication configuration
// DO NOT commit this file to public repositories!

import Foundation

struct CognitoConfig {
    
    /// AWS Cognito User Pool ID
    /// Example: us-east-1_AbCdEfGhI
    static let userPoolId = "us-east-1_V2s48Yy0h"
    
    /// App Client ID for PlasticProphet iOS app
    /// Example: 1a2b3c4d5e6f7g8h9i0j
    static let appClientId = "4odq1p8fovp5vtmjobhdqke2rl"
    
    /// AWS Region where User Pool is hosted
    /// Example: us-east-1, us-west-2, eu-west-1
    static let region = "us-east-1"
    
    /// Cognito Domain Prefix - This is configured in AWS Cognito Console
    /// Your domain: https://us-east-1v2s48yy0h.auth.us-east-1.amazoncognito.com
    static let domainPrefix = "us-east-1v2s48yy0h"
    
    // MARK: - Validation
    
    /// Check if credentials are properly configured
    static var isConfigured: Bool {
        return !userPoolId.contains("YOUR_") &&
               !appClientId.contains("YOUR_") &&
               !region.contains("YOUR_") &&
               !domainPrefix.contains("YOUR_")
    }
    
    /// Print configuration status for debugging
    static func printStatus() {
        print("=== AWS Cognito Configuration ===")
        print("User Pool ID: \(userPoolId)")
        print("App Client ID: \(appClientId)")
        print("Region: \(region)")
        print("Domain Prefix: \(domainPrefix)")
        print("Configured: \(isConfigured ? "✅ YES" : "❌ NO")")
        print("================================")
    }
}

// MARK: - Security Note
/*
 ⚠️ IMPORTANT SECURITY NOTES:
 
 1. These values are NOT secret - they're safe to include in your app
 2. The User Pool ID and Client ID are meant to be public
 3. However, you should NEVER commit:
    - User passwords
    - AWS Secret Keys
    - API tokens/secrets
 
 4. To keep this file out of git:
    - Add "CognitoConfig.swift" to .gitignore
    - Or use Xcode build configurations
 
 5. For production apps, consider using:
    - AWS Amplify CLI to generate this automatically
    - Environment-specific configs (dev, staging, prod)
*/
