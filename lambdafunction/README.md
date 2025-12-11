# MerchantResolverFn - Lambda Function

AWS Lambda function for processing merchant data, normalizing merchant names, matching MCC codes, and writing to RDS PostgreSQL.

## 🎯 Function Overview

This Lambda function handles the complete merchant data pipeline:
1. Receives merchant location data from iOS app
2. Normalizes merchant names (removes special chars, standardizes format)
3. Matches generalized names to MCC (Merchant Category Codes)
4. Writes merchant data to RDS PostgreSQL `rolling_merchant` table
5. Returns normalized data and MCC code to caller

## 📡 API Endpoint

```
POST https://0vl413zppl.execute-api.us-east-1.amazonaws.com/MerchantInfo
```

## 📥 Request Format

```json
{
  "userId": "user_123",
  "merchantName": "STARBUCKS COFFEE",
  "latitude": 37.3382,
  "longitude": -122.0309
}
```

## 📤 Response Format

**Success (200):**
```json
{
  "statusCode": 200,
  "body": {
    "recordId": 12345,
    "merchantName": "STARBUCKS",
    "mcc": "5810",
    "categoryKey": "Restaurants",
    "message": "Successfully processed merchant data"
  }
}
```

**Error (400/500):**
```json
{
  "statusCode": 400,
  "body": {
    "error": "Missing required fields: userId, merchantName, latitude, longitude"
  }
}
```

## 🗂️ File Structure

```
lambdafunction/
├── lambda_function.py       [Main handler - processes requests, writes to DB]
├── normalization.py         [Cleans merchant names]
├── mcc_directory.py         [Loads and searches MCC codes]
├── requirements.txt         [Python dependencies]
├── data/
│   └── mcc_codes.json       [MCC reference database]
└── README.md                [This file]
```

## 🔧 Environment Variables

Set these in AWS Lambda configuration. **DO NOT hardcode credentials.**

| Variable | Description | Example |
|----------|-------------|---------|
| `DB_HOST` | RDS endpoint | `plasticprophet-db.cg1cy2qk2qui.us-east-1.rds.amazonaws.com` |
| `DB_PORT` | PostgreSQL port | `5432` |
| `DB_NAME` | Database name | `plasticprophetdb` |
| `DB_USER` | Database user | `plasticadmin` |
| `DB_PASSWORD` | Database password | Set in Lambda (not in code) |

## 📋 Database Requirements

Your PostgreSQL database must have this table:

```sql
CREATE TABLE rolling_merchant (
  id SERIAL PRIMARY KEY,
  user_id VARCHAR(255) NOT NULL,
  generalized_name VARCHAR(255),
  mcc_code VARCHAR(10),
  category_key VARCHAR(255),
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_user_id ON rolling_merchant(user_id);
CREATE INDEX idx_detected_at ON rolling_merchant(detected_at);
```

## 📦 Dependencies

Only one external package (specified in `requirements.txt`):

```
psycopg2-binary==2.9.7
```

**Note:** Use `psycopg2-binary` (not regular `psycopg2`) for AWS Lambda compatibility.

### Install Dependencies

```bash
cd lambdafunction
pip install -r requirements.txt
```

## 🚀 Deployment Steps

### 1. Package the Function

```bash
cd /Users/valentinakapiti/Documents/PlasticProphet/lambdafunction

zip -r lambda_function.zip \
  lambda_function.py \
  normalization.py \
  mcc_directory.py \
  data/mcc_codes.json \
  -x "venv/*" "*.pyc" "__pycache__/*"
```

### 2. Create Lambda Function (First Time)

```bash
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws lambda create-function \
  --function-name MerchantResolverFn \
  --runtime python3.11 \
  --role arn:aws:iam::${AWS_ACCOUNT_ID}:role/lambda-rds-role \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://lambda_function.zip \
  --timeout 30 \
  --memory-size 256 \
  --region us-east-1
```

### 3. Set Environment Variables

```bash
aws lambda update-function-configuration \
  --function-name MerchantResolverFn \
  --environment Variables='{
    DB_HOST=plasticprophet-db.cg1cy2qk2qui.us-east-1.rds.amazonaws.com,
    DB_PORT=5432,
    DB_NAME=plasticprophetdb,
    DB_USER=plasticadmin,
    DB_PASSWORD=Database123!
  }' \
  --region us-east-1
```

### 4. Update Function Code (After Changes)

```bash
# Repackage
zip -r lambda_function.zip lambda_function.py normalization.py mcc_directory.py data/

# Update
aws lambda update-function-code \
  --function-name MerchantResolverFn \
  --zip-file fileb://lambda_function.zip \
  --region us-east-1
```

## 🧪 Testing

### Via cURL

```bash
curl -X POST https://0vl413zppl.execute-api.us-east-1.amazonaws.com/MerchantInfo \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user_123",
    "merchantName": "STARBUCKS COFFEE",
    "latitude": 37.3382,
    "longitude": -122.0309
  }' | jq .
```

### Via AWS CLI

```bash
aws lambda invoke \
  --function-name MerchantResolverFn \
  --payload '{"body":"{\"userId\":\"user_123\",\"merchantName\":\"STARBUCKS COFFEE\",\"latitude\":37.3382,\"longitude\":-122.0309}"}' \
  --region us-east-1 \
  response.json

cat response.json
```

### Verify Data in Database

```bash
psql -h plasticprophet-db.cg1cy2qk2qui.us-east-1.rds.amazonaws.com \
     -U plasticadmin \
     -d plasticprophetdb \
     -c "SELECT * FROM rolling_merchant ORDER BY detected_at DESC LIMIT 5;"
```

## 📊 Data Processing Flow

```
Request arrives at API Gateway
    ↓
Lambda receives POST with userId, merchantName, latitude, longitude
    ↓
normalize_poi_name() cleans merchant name
  "STARBUCKS COFFEE" → "STARBUCKS"
    ↓
find_mcc_for_merchant_name() matches MCC
  "STARBUCKS" → MCC "5810" (Restaurants)
    ↓
write_to_rolling_merchant() inserts to RDS
  INSERT INTO rolling_merchant (...)
    ↓
Return response with recordId, mcc, categoryKey
```

## 🔍 Understanding Each Module

### lambda_function.py
**Entry point** for the Lambda function.

- `lambda_handler(event, context)` - Main handler, orchestrates the pipeline
- `write_to_rolling_merchant(...)` - Writes normalized data to PostgreSQL

Environment variables used:
- `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`

### normalization.py
**Cleans and standardizes** merchant names.

- `normalize_poi_name(raw)` - Converts to uppercase, removes special chars, applies overrides

Example:
```python
normalize_poi_name("STARBUCKS COFFEE!!")  # Returns: "STARBUCKS COFFEE"
```

### mcc_directory.py
**Loads MCC database** and finds matching codes.

- `load_mcc_directory()` - Loads MCC codes from JSON (called once on cold start)
- `find_mcc_for_merchant_name(name)` - Searches and returns MCC code + category

Example:
```python
find_mcc_for_merchant_name("STARBUCKS")  
# Returns: {"mcc": "5810", "categoryKey": "Restaurants"}
```

### data/mcc_codes.json
**Reference database** of Merchant Category Codes.

## 🐛 Troubleshooting

### Import Error: "No module named 'psycopg2'"
```bash
pip install psycopg2-binary
zip -r lambda_function.zip lambda_function.py normalization.py mcc_directory.py data/
aws lambda update-function-code --function-name MerchantResolverFn --zip-file fileb://lambda_function.zip
```

### Connection Refused / Timeout
Check:
1. Environment variables are correct: `aws lambda get-function-configuration --function-name MerchantResolverFn --query 'Environment.Variables'`
2. RDS security group allows port 5432
3. Database credentials are valid

Test RDS connection:
```bash
psql -h plasticprophet-db.cg1cy2qk2qui.us-east-1.rds.amazonaws.com \
     -U plasticadmin \
     -d plasticprophetdb \
     -c "SELECT 1;"
```

### API Returns 500 Error
View CloudWatch logs:
```bash
aws logs tail /aws/lambda/MerchantResolverFn --follow --region us-east-1
```

## 📈 Monitoring

### View Logs

```bash
aws logs tail /aws/lambda/MerchantResolverFn --follow --region us-east-1
```

### Check Environment Variables

```bash
aws lambda get-function-configuration --function-name MerchantResolverFn --query 'Environment.Variables'
```

## 🎓 Common MCC Codes

| MCC | Category |
|-----|----------|
| 5810 | Restaurants |
| 5411 | Grocery Stores |
| 5541 | Gas Stations |
| 5912 | Drug Stores |
| 5311 | Department Stores |

## ⚡ Performance

- **Cold Start:** 2-3 seconds (MCC data loads once)
- **Warm Start:** 200-500ms
- **Database Write:** 50-100ms
- **Memory:** 256MB
- **Timeout:** 30 seconds

---

**Function Name:** MerchantResolverFn
**Runtime:** Python 3.11
**Handler:** lambda_function.lambda_handler
**Region:** us-east-1
**Database:** PostgreSQL (RDS)
**Status:** Production Ready
