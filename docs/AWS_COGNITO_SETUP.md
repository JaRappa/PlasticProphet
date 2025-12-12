# AWS Cognito Configuration - Step-by-Step Guide

## Prerequisites
- AWS Console access
- Your User Pool ID: `us-east-1_V2s48Yy0h`
- Your App Client ID: `4odq1p8fovp5vtmjobhdqke2rl`
- Region: `us-east-1`

---

## Step 1: Navigate to Your App Client

1. Open AWS Console: https://console.aws.amazon.com/cognito/
2. Click on **User Pools** in the left sidebar
3. Click on your user pool: **us-east-1_V2s48Yy0h**
4. In the left sidebar, go to **App integration** → **App clients and analytics**
5. You should see your app client listed
6. Click on the app client ID: **4odq1p8fovp5vtmjobhdqke2rl**

---

## Step 2: Edit App Client Settings

1. Click the **Edit the app client** button
2. You'll see various configuration options

### Section A: Authentication Flows Configuration

**FIND THIS SECTION:** Look for "Authentication flows configuration"

**Current state (WRONG):**
- ✅ ALLOW_USER_PASSWORD_AUTH (checked - this is the problem!)
- ⬜ ALLOW_AUTHORIZATION_CODE_AUTH (unchecked - we need this!)

**Change to (CORRECT):**
- ❌ UNCHECK: ALLOW_USER_PASSWORD_AUTH
- ✅ CHECK: ALLOW_AUTHORIZATION_CODE_AUTH
- ✅ CHECK: ALLOW_REFRESH_TOKEN_AUTH
- (Leave other options as they are)

**Screenshot reference:**
```
[✓] ALLOW_ADMIN_USER_PASSWORD_AUTH
[✗] ALLOW_CUSTOM_AUTH
[ ] ALLOW_USER_PASSWORD_AUTH          ← UNCHECK THIS
[✓] ALLOW_AUTHORIZATION_CODE_AUTH     ← CHECK THIS
[✓] ALLOW_REFRESH_TOKEN_AUTH          ← CHECK THIS
[ ] ALLOW_SRP_AUTH
```

---

## Step 3: Configure Allowed Callback URLs

**FIND THIS SECTION:** Scroll down to "Allowed callback URLs"

**Add this exact URL:**
```
plasticprophet://auth-callback
```

**Screenshot:**
```
Allowed callback URLs:
┌─────────────────────────────────────┐
│ plasticprophet://auth-callback      │
└─────────────────────────────────────┘
```

---

## Step 4: Configure Allowed Sign-out URLs

**FIND THIS SECTION:** Look for "Allowed sign-out URLs"

**Add this exact URL:**
```
plasticprophet://auth-callback
```

**Screenshot:**
```
Allowed sign-out URLs:
┌─────────────────────────────────────┐
│ plasticprophet://auth-callback      │
└─────────────────────────────────────┘
```

---

## Step 5: Verify App Client Type

**FIND THIS SECTION:** Look for "App client type" or "Client type"

**Should be set to:**
- ✅ **Public** (NOT "Confidential")

If it shows "Confidential", you may need to create a new app client or contact AWS support to change it.

---

## Step 6: Save Changes

1. Click the **Save changes** button at the bottom
2. **Wait 30-60 seconds** for changes to propagate through AWS

---

## Step 7: Create/Verify Cognito Domain

Now you need to set up the Cognito Hosted UI domain so users can sign in.

### 7A: Go to Domain Name Settings

1. Still in your User Pool, go to **App integration** → **Domain name** (in left sidebar)
2. You'll see either:
   - A domain already created, OR
   - A button to "Create domain"

### 7B: Create Domain (if needed)

1. Click **Create domain** 
2. Enter a domain name (must be unique across AWS):
   - Recommended: `plasticprophet` (or `plasticprophet-yourinitials`)
   - Full domain will be: `plasticprophet.auth.us-east-1.amazoncognito.com`

3. Click **Create domain**
4. **Wait a few minutes** for domain creation (shows "PENDING" → "ACTIVE")

### 7C: Note Your Domain

Once created, you should see:
```
Domain name: plasticprophet
Domain status: ACTIVE
Domain URL: https://plasticprophet.auth.us-east-1.amazoncognito.com
```

**Keep this URL handy** - your app uses it to authenticate users.

---

## Step 8: Verify Your Code Has the Right Domain

The domain is automatically built in your code by this line in `CognitoAuthServiceNoSDK.swift`:

```swift
private var hostedUIURL: String {
    "https://\(CognitoConfig.userPoolId.split(separator: "_")[1]).auth.\(CognitoConfig.region).amazoncognito.com"
}
```

This extracts `V2s48Yy0h` from your user pool ID `us-east-1_V2s48Yy0h` and builds:
```
https://V2s48Yy0h.auth.us-east-1.amazoncognito.com
```

✅ **This should match your Cognito domain!**

---

## Step 9: Verify Your App Client Has "Public" Type

1. Go back to **App clients and analytics**
2. Click your app client
3. Look for **App client type** or **Client type** setting
4. It should say **"Public"** ✅
5. If it says **"Confidential"**, you may need to delete this client and create a new one with type "Public"

---

## Step 10: Testing Your Configuration

Once everything is saved:

1. **Close AWS Console** (so changes fully propagate)
2. **Wait 1 minute**
3. **Build your app in Xcode** (⌘B)
4. **Run your app** (⌘R)
5. **Navigate to Sign In screen**
6. **Tap "Continue to Sign In"**
7. You should see a professional Cognito login page in Safari

---

## Checklist ✓

Before you test, verify all of these:

- [ ] ❌ ALLOW_USER_PASSWORD_AUTH is UNCHECKED
- [ ] ✅ ALLOW_AUTHORIZATION_CODE_AUTH is CHECKED
- [ ] ✅ ALLOW_REFRESH_TOKEN_AUTH is CHECKED
- [ ] ✅ Callback URL: `plasticprophet://auth-callback` (exact match)
- [ ] ✅ Sign-out URL: `plasticprophet://auth-callback` (exact match)
- [ ] ✅ App client type is "Public"
- [ ] ✅ Cognito domain is ACTIVE
- [ ] ✅ Info.plist has `<string>plasticprophet</string>` URL scheme
- [ ] ✅ Code has correct CognitoConfig values

---

## Troubleshooting

### "Failed to start authentication session"
- Check that your Info.plist URL scheme is correct: `plasticprophet`
- Verify the URL scheme matches what's in your code

### "Invalid redirect_uri"
- Make sure callback URL is EXACTLY: `plasticprophet://auth-callback`
- Check for trailing spaces or typos
- Save changes and wait 60 seconds

### "Unauthorized client"
- Verify ALLOW_AUTHORIZATION_CODE_AUTH is checked
- Verify ALLOW_USER_PASSWORD_AUTH is unchecked
- Verify app client type is "Public"

### "The app client does not allow authorization code flow"
- Your app client type might be "Confidential"
- You may need to create a new app client with type "Public"

### Users see blank page or error
- Wait 2-3 minutes after saving - changes need to propagate
- Check that your domain is ACTIVE (not PENDING)
- Verify callback URL doesn't have typos

---

## Key URLs Reference

**Your Cognito Domain:**
```
https://V2s48Yy0h.auth.us-east-1.amazoncognito.com
```

**Your Authorization Endpoint:**
```
https://V2s48Yy0h.auth.us-east-1.amazoncognito.com/oauth2/authorize
```

**Your Token Endpoint:**
```
https://V2s48Yy0h.auth.us-east-1.amazoncognito.com/oauth2/token
```

**Your Callback URL (must match in AWS):**
```
plasticprophet://auth-callback
```

---

## Still Having Issues?

If something isn't working after these steps:

1. Take a screenshot of your AWS app client settings
2. Verify all 8 checkboxes above are complete
3. Rebuild your Xcode project from scratch (⌘Shift+K then ⌘B)
4. Check the Xcode console for specific error messages
5. Share those error messages - they usually say exactly what's wrong

Good luck! 🚀
