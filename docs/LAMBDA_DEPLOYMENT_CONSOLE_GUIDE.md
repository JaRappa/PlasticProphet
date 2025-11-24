# 🚀 Complete Lambda Deployment Guide (AWS Console)
## Step-by-Step for Beginners - No Command Line Required

**Estimated Time:** 60-75 minutes  
**Difficulty:** Beginner-friendly  
**What You'll Deploy:** 2 Lambda functions + permissions + API Gateway

---

## 📋 What You'll Need

Before starting, gather this information:

- ✅ AWS Account with admin access
- ✅ RDS Proxy Endpoint: `proxy-1762399671009-plasticprophet-db.proxy-cg1cy2qk2qui.us-east-1.rds.amazonaws.com`
- ✅ Database Name: `plasticprophet`
- ✅ Database Username: `plasticadmin`
- ✅ Database Password: `Database123!`
- ✅ Cognito User Pool ID: `us-east-1_V2s48Yy0h`
- ✅ VPC ID: `vpc-09dc56b4f1c23efde`
- ✅ RDS Security Group: `sg-03d22c664992b6e7`

---

# Part 1: Prepare Lambda Package Files

## Step 1.1: Package PostConfirmationTrigger

**On Your Mac (Terminal):**

```bash
cd /Users/carolinezanuto/Documents/PlasticProphet/lambda/PostConfirmationTrigger

# Install dependencies
pip3 install pg8000 -t .

# Create ZIP file
zip -r PostConfirmationTrigger.zip lambda_function.py pg8000/
```

**What this creates:** `PostConfirmationTrigger.zip` file (you'll upload this to AWS)

---

## Step 1.2: Package GetProfileAPI

**On Your Mac (Terminal):**

```bash
cd /Users/carolinezanuto/Documents/PlasticProphet/lambda/GetProfileAPI

# Install dependencies
pip3 install pg8000 -t .

# Create ZIP file
zip -r GetProfileAPI.zip lambda_function.py pg8000/
```

**What this creates:** `GetProfileAPI.zip` file (you'll upload this to AWS)

---

# Part 2: Create IAM Role for Lambda

## Step 2.1: Open IAM Console

1. Go to: https://console.aws.amazon.com
2. Sign in to your AWS account
3. In the search bar at top, type **"IAM"**
4. Click **"IAM"** service

---

## Step 2.2: Create New Role

1. In left sidebar, click **"Roles"**
2. Click orange **"Create role"** button
3. On "Select trusted entity" page:
   - **Trusted entity type:** AWS service
   - **Use case:** Lambda (select it from the list)
4. Click **"Next"** button

---

## Step 2.3: Attach Permission Policies

In the search box, search for and **check the box** next to these policies:

1. ✅ **AWSLambdaBasicExecutionRole**
   - (Allows Lambda to write logs to CloudWatch)
   
2. ✅ **AWSLambdaVPCAccessExecutionRole**
   - (Allows Lambda to access resources in your VPC)

**How to find them:**
- Type policy name in search box
- Click the checkbox next to it
- Search for the next one

After both are checked, click **"Next"**

---

## Step 2.4: Name and Create Role

1. **Role name:** `PlasticProphetLambdaRole`
2. **Description:** `Execution role for PlasticProphet Lambda functions`
3. Scroll down and click **"Create role"** (orange button)

**✅ Success:** You should see "Role PlasticProphetLambdaRole created"

---

# Part 3: Create Lambda Security Group

## Step 3.1: Open EC2 Console

1. In AWS Console search bar, type **"EC2"**
2. Click **"EC2"** service
3. In left sidebar, scroll down and click **"Security Groups"**

---

## Step 3.2: Create New Security Group

1. Click orange **"Create security group"** button
2. Fill in the form:
   - **Security group name:** `lambda-rds-access-sg`
   - **Description:** `Allows Lambda functions to access RDS`
   - **VPC:** Select `vpc-09dc56b4f1c23efde` from dropdown

---

## Step 3.3: Configure Outbound Rules

1. Scroll to **"Outbound rules"** section
2. Leave the default rule (All traffic to 0.0.0.0/0)
3. Click **"Create security group"** (orange button at bottom)

**✅ Success:** Note the Security Group ID (e.g., `sg-0abc123...`)  
**Copy this ID - you'll need it later!**

---

## Step 3.4: Update RDS Security Group

Now we allow Lambda to connect to RDS:

1. Still in **Security Groups** list
2. Find security group: `sg-03d22c664992b6e7` (your RDS security group)
3. Click on it
4. Click **"Inbound rules"** tab
5. Click **"Edit inbound rules"** button
6. Click **"Add rule"** button
7. Configure the new rule:
   - **Type:** PostgreSQL (automatically sets port 5432)
   - **Source:** Custom
   - **Source dropdown:** Search for `lambda-rds-access-sg` and select it
   - **Description:** `Allow Lambda functions to access RDS`
8. Click **"Save rules"** (orange button)

**✅ Success:** Lambda can now talk to your RDS database!

---

# Part 4: Get VPC Subnet IDs

## Step 4.1: Find Private Subnets

1. In EC2 Console left sidebar, click **"Subnets"**
2. You'll see a list of subnets
3. Look at the **VPC ID** column - find ones with `vpc-09dc56b4f1c23efde`
4. Find **2 private subnets** (look for ones with "private" in the name or check Route Table)
5. **Copy both Subnet IDs** (e.g., `subnet-0abc123...` and `subnet-0def456...`)

**✅ You need at least 2 subnet IDs for Lambda VPC configuration**

**Common private subnet patterns:**
- Name contains "private"
- Route table doesn't have an Internet Gateway
- Usually in different Availability Zones

---

# Part 5: Deploy PostConfirmationTrigger Lambda

## Step 5.1: Open Lambda Console

1. In AWS Console search bar, type **"Lambda"**
2. Click **"Lambda"** service
3. Click orange **"Create function"** button

---

## Step 5.2: Create Function

1. Select **"Author from scratch"**
2. Fill in the form:
   - **Function name:** `PostConfirmationTrigger`
   - **Runtime:** Python 3.12 (or latest Python 3.x)
   - **Architecture:** x86_64
3. Expand **"Change default execution role"**:
   - Select **"Use an existing role"**
   - **Existing role:** Select `PlasticProphetLambdaRole` from dropdown
4. Click **"Create function"** (orange button)

**✅ Success:** Function created! Now configure it...

---

## Step 5.3: Upload Lambda Code

1. You're now on the function page
2. Scroll down to **"Code source"** section
3. Click **"Upload from"** dropdown button
4. Select **".zip file"**
5. Click **"Upload"** button
6. Navigate to: `/Users/carolinezanuto/Documents/PlasticProphet/lambda/PostConfirmationTrigger/PostConfirmationTrigger.zip`
7. Select the file and click **"Open"**
8. Click **"Save"** button

**⏳ Wait:** Upload takes 10-20 seconds  
**✅ Success:** You'll see `lambda_function.py` in the code editor

---

## Step 5.4: Configure Environment Variables

1. Click **"Configuration"** tab (top of page)
2. In left sidebar, click **"Environment variables"**
3. Click **"Edit"** button
4. Click **"Add environment variable"** for each of these:

**Add these 4 variables:**

| Key | Value |
|-----|-------|
| `DB_HOST` | `proxy-1762399671009-plasticprophet-db.proxy-cg1cy2qk2qui.us-east-1.rds.amazonaws.com` |
| `DB_NAME` | `plasticprophet` |
| `DB_USER` | `plasticadmin` |
| `DB_PASSWORD` | `Database123!` |

5. Click **"Save"** button (orange)

**✅ Success:** 4 environment variables configured

---

## Step 5.5: Configure VPC Settings

1. Still in **"Configuration"** tab
2. In left sidebar, click **"VPC"**
3. Click **"Edit"** button
4. Configure:
   - **VPC:** Select `vpc-09dc56b4f1c23efde`
   - **Subnets:** Select the 2 private subnets you found in Step 4.1
   - **Security groups:** Select `lambda-rds-access-sg` (the one you created)
5. Click **"Save"** button

**⏳ Wait:** VPC configuration takes 1-2 minutes  
**✅ Success:** Status shows "VPC: vpc-09dc56b4f1c23efde"

---

## Step 5.6: Increase Timeout

1. Still in **"Configuration"** tab
2. In left sidebar, click **"General configuration"**
3. Click **"Edit"** button
4. Change:
   - **Timeout:** `30` seconds (increase from default 3)
   - **Memory:** 256 MB (can leave as is)
5. Click **"Save"** button

**✅ Success:** Lambda now has 30 seconds to complete (database connections can be slow)

---

## Step 5.7: Link to Cognito User Pool

1. Go back to AWS Console home
2. Search for **"Cognito"**
3. Click **"Cognito"** service
4. Click **"Manage User Pools"**
5. Click on your pool: `us-east-1_V2s48Yy0h`
6. In left sidebar, click **"Triggers"**
7. Find **"Post confirmation"** in the list
8. Click the dropdown next to it
9. Select **`PostConfirmationTrigger`**
10. Click **"Save changes"** (bottom right)

**A popup may appear asking for permission - click "Add permissions"**

**✅ Success:** Cognito will now trigger this Lambda after email confirmation!

---

# Part 6: Deploy GetProfileAPI Lambda

## Step 6.1: Create Second Function

1. Go back to **Lambda Console**
2. Click **"Create function"** (orange button)
3. Fill in:
   - **Function name:** `GetProfileAPI`
   - **Runtime:** Python 3.12
   - **Architecture:** x86_64
4. Expand **"Change default execution role"**:
   - Select **"Use an existing role"**
   - **Existing role:** `PlasticProphetLambdaRole`
5. Click **"Create function"**

---

## Step 6.2: Upload Code

1. Scroll to **"Code source"** section
2. Click **"Upload from"** → **".zip file"**
3. Click **"Upload"**
4. Navigate to: `/Users/carolinezanuto/Documents/PlasticProphet/lambda/GetProfileAPI/GetProfileAPI.zip`
5. Click **"Open"**
6. Click **"Save"**

**✅ Success:** Code uploaded!

---

## Step 6.3: Configure Environment Variables

Same as PostConfirmationTrigger:

1. Click **"Configuration"** tab
2. Click **"Environment variables"** (left sidebar)
3. Click **"Edit"**
4. Add the same 4 variables:

| Key | Value |
|-----|-------|
| `DB_HOST` | `proxy-1762399671009-plasticprophet-db.proxy-cg1cy2qk2qui.us-east-1.rds.amazonaws.com` |
| `DB_NAME` | `plasticprophet` |
| `DB_USER` | `plasticadmin` |
| `DB_PASSWORD` | `Database123!` |

5. Click **"Save"**

---

## Step 6.4: Configure VPC

1. Click **"VPC"** (left sidebar)
2. Click **"Edit"**
3. Configure:
   - **VPC:** `vpc-09dc56b4f1c23efde`
   - **Subnets:** Same 2 private subnets
   - **Security groups:** `lambda-rds-access-sg`
4. Click **"Save"**

**⏳ Wait 1-2 minutes for VPC configuration**

---

## Step 6.5: Increase Timeout

1. Click **"General configuration"** (left sidebar)
2. Click **"Edit"**
3. Change **Timeout:** `30` seconds
4. Click **"Save"**

**✅ Success:** GetProfileAPI Lambda is deployed!

---

# Part 7: Create HTTP API Gateway

## Step 7.1: Open API Gateway Console

1. In AWS Console search bar, type **"API Gateway"**
2. Click **"API Gateway"** service
3. Click **"Create API"** (orange button)

---

## Step 7.2: Choose HTTP API

1. Find the **"HTTP API"** card (first option)
2. Click **"Build"** button under it

---

## Step 7.3: Add Integration

1. Click **"Add integration"** button
2. Select **"Lambda"** from dropdown
3. **AWS Region:** us-east-1
4. **Lambda function:** Search and select `GetProfileAPI`
5. **API name:** `PlasticProphetAPI`
6. Click **"Next"** button

---

## Step 7.4: Configure Route

1. You'll see a route auto-created: `GET /GetProfileAPI`
2. **Click on the route path** to edit it
3. Change **Resource path** from `/GetProfileAPI` to `/profile`
4. Keep **Method** as `GET`
5. Click **"Next"** button

---

## Step 7.5: Configure Stage

1. **Stage name:** Keep as `$default` (this auto-deploys)
2. **Auto-deploy:** ✅ Checked (enabled by default)
3. Click **"Next"** button

---

## Step 7.6: Review and Create

1. Review your settings:
   - Integration: Lambda - GetProfileAPI
   - Route: GET /profile
   - Stage: $default
2. Click **"Create"** button (orange)

**✅ Success:** API created!

---

## Step 7.7: Copy Your API Endpoint

1. On the API overview page, look for **"Invoke URL"**
2. It looks like: `https://abc123xyz.execute-api.us-east-1.amazonaws.com`
3. **COPY THIS URL** - you'll need it!

**Your full endpoint is:** `https://abc123xyz.execute-api.us-east-1.amazonaws.com/profile`
https://0vl413zppl.execute-api.us-east-1.amazonaws.com
---

# Part 8: Add JWT Authorizer (Cognito)

## Step 8.1: Create Authorizer

1. In your API Gateway console (still on PlasticProphetAPI)
2. In left sidebar, click **"Authorization"**
3. Click **"Manage authorizers"**
4. Click **"Create"** button

---

## Step 8.2: Configure JWT Authorizer

Fill in the form:

1. **Authorizer type:** JWT
2. **Name:** `CognitoAuthorizer`
3. **Identity source:** `$request.header.Authorization`
4. **Issuer URL:** `https://cognito-idp.us-east-1.amazonaws.com/us-east-1_V2s48Yy0h`
5. **Audience:** Leave blank (we're using User Pool, not App Client)

However, if you run into authentication issues later, you might need to come back and update the Audience field with your Cognito App Client ID.
To find your App Client ID if needed:

Go to Cognito → User Pools → Your User Pool
Click on App integration tab
Scroll down to App clients and analytics
You'll see your App Client ID there

Click **"Create"** button

**✅ Success:** Authorizer created!

---

## Step 8.3: Attach Authorizer to Route

1. In left sidebar, click **"Routes"**
2. Click on **`GET /profile`** route
3. Click **"Attach authorization"** button
4. **Authorizer:** Select `CognitoAuthorizer` from dropdown
5. **Authorization scopes:** Leave blank
6. Click **"Attach authorizer"** button

**✅ Success:** Route now requires Cognito JWT token!

---

# Part 9: Enable CORS

## Step 9.1: Configure CORS

1. In left sidebar, click **"CORS"**
2. Click **"Configure"** button
3. Settings:
   - **Access-Control-Allow-Origin:** `*` (or your specific domain)
   - **Access-Control-Allow-Headers:** `authorization,content-type`
   - **Access-Control-Allow-Methods:** Select `GET` and `OPTIONS`
   - **Access-Control-Max-Age:** `300` (optional)
4. Click **"Save"** button

**✅ Success:** CORS enabled - your iOS app can now call this API!

---

# Part 10: Update iOS App

## Step 10.1: Update API URL in Swift Code

1. Open Xcode
2. Open file: `CognitoAuthServiceNoSDK.swift`
3. Find line 375 (in `getUserProfile()` method):

```swift
let apiURL = "https://syidcdnccc.execute-api.us-east-1.amazonaws.com/prod/profile"
```

4. Replace with your new API endpoint:

```swift
let apiURL = "https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/profile"
```

**Replace `YOUR_API_ID` with the actual ID from Step 7.7!**

5. Save the file (⌘+S)

**✅ Success:** iOS app now points to your deployed API!

---

# Part 11: Test Everything

## Step 11.1: Test PostConfirmationTrigger

**Test in AWS Console:**

1. Go to **Lambda** → `PostConfirmationTrigger`
2. Click **"Test"** tab
3. Click **"Create new test event"**
4. **Event name:** `TestConfirmation`
5. **Template:** Leave as "hello-world"
6. Replace JSON with:

```json
{
  "request": {
    "userAttributes": {
      "sub": "test-user-123-abc-456",
      "email": "test@example.com"
    }
  }
}
```

7. Click **"Save"**
8. Click **"Test"** button

**✅ Expected Result:** 
- Status: Succeeded
- Check database - you should see a user with `username = "cognito:test-user-123-abc-456"`

---

## Step 11.2: Test GetProfileAPI

**Test in API Gateway:**

1. Go to **API Gateway** → `PlasticProphetAPI`
2. Click **"Routes"** → `GET /profile`
3. Unfortunately, HTTP API doesn't have a built-in test tool
4. You'll need to test with a real Cognito token (see below)

**Test with curl (requires valid Cognito token):**

```bash
curl -X GET \
  https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/profile \
  -H "Authorization: Bearer YOUR_COGNITO_ID_TOKEN"
```

---

## Step 11.3: Test Full Flow in iOS App

1. Build and run your iOS app in Xcode
2. **Sign up** with a new email address
3. **Check email** and confirm with the code
4. **Sign in** with OAuth (Cognito Hosted UI)
5. Check Xcode console logs - you should see:

```
✅ Secure sign in successful!
🔍 Fetching user profile from database via API Gateway...
📥 Profile API response: 200
✅ User profile loaded from database: your@email.com
```

**✅ Success:** Everything is working end-to-end!

---

# 🎯 Final Verification Checklist

Go through this checklist to make sure everything is configured:

### **Lambda Functions**
- [ ] PostConfirmationTrigger deployed with code
- [ ] PostConfirmationTrigger has 4 environment variables set
- [ ] PostConfirmationTrigger configured with VPC (2 subnets + security group)
- [ ] PostConfirmationTrigger timeout set to 30 seconds
- [ ] PostConfirmationTrigger linked to Cognito User Pool
- [ ] GetProfileAPI deployed with code
- [ ] GetProfileAPI has 4 environment variables set
- [ ] GetProfileAPI configured with VPC (same as PostConfirmationTrigger)
- [ ] GetProfileAPI timeout set to 30 seconds

### **IAM & Permissions**
- [ ] PlasticProphetLambdaRole exists
- [ ] Role has AWSLambdaBasicExecutionRole policy
- [ ] Role has AWSLambdaVPCAccessExecutionRole policy
- [ ] Both Lambdas use this role

### **Networking**
- [ ] lambda-rds-access-sg security group created
- [ ] RDS security group (sg-03d22c664992b6e7) allows inbound from lambda-rds-access-sg
- [ ] Lambda functions use 2 private subnets in correct VPC

### **API Gateway**
- [ ] HTTP API created (PlasticProphetAPI)
- [ ] Route `GET /profile` exists
- [ ] Route connected to GetProfileAPI Lambda
- [ ] CognitoAuthorizer created with correct Issuer URL
- [ ] Authorizer attached to `/profile` route
- [ ] CORS enabled with Authorization header

### **iOS App**
- [ ] API URL updated in CognitoAuthServiceNoSDK.swift
- [ ] App builds without errors
- [ ] getUserProfile() method uses correct endpoint

---

# 🔍 Troubleshooting Common Issues

## Issue: "Task timed out after 30 seconds"

**Cause:** Lambda can't reach RDS database

**Fix:**
1. Check Lambda is in **private subnets** (not public)
2. Check RDS security group allows Lambda security group
3. Check RDS Proxy endpoint is correct in environment variables

---

## Issue: "Unable to import module 'lambda_function'"

**Cause:** ZIP file structure is wrong

**Fix:**
1. Make sure `lambda_function.py` is in the root of the ZIP
2. Recreate ZIP with: `zip -r function.zip lambda_function.py pg8000/`

---

## Issue: "Unauthorized" when calling API

**Cause:** JWT authorizer not working

**Fix:**
1. Check Issuer URL matches your User Pool
2. Make sure you're using the **ID token**, not access token
3. Verify authorizer is attached to the route

---

## Issue: API returns 500 error

**Cause:** Lambda function error

**Fix:**
1. Go to CloudWatch Logs
2. Find log group: `/aws/lambda/GetProfileAPI`
3. Check latest log stream for error details
4. Common issues:
   - Database credentials wrong
   - User doesn't exist in database
   - VPC connectivity issues

---

## Issue: CORS error in iOS app

**Cause:** CORS not configured properly

**Fix:**
1. Check CORS includes `authorization` in allowed headers
2. Check CORS origin is `*` or your specific domain
3. Make sure both GET and OPTIONS methods are allowed

---

# 📊 How to Monitor Your Lambda Functions

## CloudWatch Logs

**View logs for PostConfirmationTrigger:**
1. Go to CloudWatch Console
2. Click "Log groups"
3. Find `/aws/lambda/PostConfirmationTrigger`
4. Click on latest log stream
5. See execution details

**View logs for GetProfileAPI:**
1. Same steps, but find `/aws/lambda/GetProfileAPI`

**What to look for:**
- ✅ "Database record created successfully"
- ✅ "Successfully retrieved user profile"
- ❌ "Error connecting to database"
- ❌ "User not found"

---

## Lambda Metrics

**Check function performance:**
1. Go to Lambda Console
2. Click on function name
3. Click "Monitor" tab
4. View:
   - Invocations (how many times called)
   - Duration (how long it takes)
   - Errors (if any failures)
   - Throttles (if hitting limits)

---

# 🎉 Congratulations!

You've successfully deployed:

✅ **2 Lambda functions** with database connectivity  
✅ **HTTP API Gateway** with Cognito authentication  
✅ **Full authentication flow** from iOS app to database  

**Your architecture:**
```
iOS App
  ↓ (Sign Up)
Cognito
  ↓ (Email Confirmed)
PostConfirmationTrigger Lambda
  ↓
PostgreSQL Database (creates user)

iOS App  
  ↓ (Sign In)
Cognito (returns JWT tokens)
  ↓ (Get Profile)
HTTP API Gateway
  ↓ (with JWT Auth)
GetProfileAPI Lambda
  ↓
PostgreSQL Database (returns profile)
  ↓
iOS App (displays profile)
```

**Next Steps:**
- Test with multiple users
- Monitor CloudWatch logs
- Add error handling in iOS app
- Consider adding more API endpoints (update profile, etc.)

---

**Need help?** Check CloudWatch logs first - they show exactly what's happening in your Lambda functions!
