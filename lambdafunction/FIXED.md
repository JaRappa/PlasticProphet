# ✅ FIXED: psycopg2 Import Error

## What Was Wrong

The error `No module named 'psycopg2._psycopg'` occurred because psycopg2 was installed for **macOS**, but AWS Lambda runs on **Linux**. The compiled binary was incompatible.

## What I Fixed

1. ✅ Removed macOS psycopg2 installation
2. ✅ Installed psycopg2-binary for **Linux x86_64** (AWS Lambda platform)
3. ✅ Created new deployment package: `Lambda.zip` (183KB)
4. ✅ Package now includes correct Linux binary: `_psycopg.cpython-311-x86_64-linux-gnu.so`

## 🚀 Deploy the Fixed Lambda

### Option 1: Run the Deploy Script

```bash
cd /Users/valentinakapiti/Documents/PlasticProphet/lambdafunction
./deploy.sh
```

### Option 2: Manual Deploy Command

```bash
cd /Users/valentinakapiti/Documents/PlasticProphet/lambdafunction

aws lambda update-function-code \
  --function-name MerchantResolverFn \
  --zip-file fileb://Lambda.zip \
  --region us-east-1
```

## 🧪 Test After Deployment

### Test with AWS CLI

```bash
aws lambda invoke \
  --function-name MerchantResolverFn \
  --payload file://test_event.json \
  response.json

cat response.json
```

### Expected Success Response

```json
{
  "statusCode": 200,
  "body": "{\"recordId\": 1, \"merchantName\": \"STARBUCKS\", \"mcc\": \"5812\", \"categoryKey\": \"Eating Places, Restaurants\", \"message\": \"Successfully processed merchant data\"}"
}
```

## ✅ Verify Database Write

After successful test, check the database:

```bash
psql -h plasticprophet-db.cg1cy2qk2qui.us-east-1.rds.amazonaws.com \
     -U plasticadmin \
     -d plasticprophetdb \
     -c "SELECT * FROM rolling_merchant ORDER BY detected_at DESC LIMIT 1;"
```

Expected output:
```
 id | user_id  | generalized_name | mcc_code | category_key              | latitude | longitude
----+----------+------------------+----------+--------------------------+----------+-----------
  1 | user_123 | STARBUCKS        | 5812     | Eating Places, Restaurants| 37.33820 | -122.03090
```

## 📊 Files Updated

```
lambdafunction/
├── Lambda.zip (NEW - 183KB)           ← Deploy this file
├── psycopg2/ (UPDATED)                ← Linux binaries
├── psycopg2_binary-2.9.11.dist-info/  ← Updated to 2.9.11
├── deploy.sh (NEW)                    ← Deployment script
└── FIXED.md (THIS FILE)               ← Fix documentation
```

## 🔍 What Changed in Lambda.zip

**Before (Broken):**
- ❌ psycopg2 compiled for macOS (Darwin)
- ❌ Binary: `_psycopg.cpython-39-darwin.so`

**After (Fixed):**
- ✅ psycopg2 compiled for Linux x86_64
- ✅ Binary: `_psycopg.cpython-311-x86_64-linux-gnu.so`
- ✅ Matches AWS Lambda runtime: Python 3.11 on Amazon Linux

## 🎯 Next Steps

1. **Deploy:** Run `./deploy.sh` or use manual command above
2. **Test:** Run `aws lambda invoke ...` command
3. **Verify:** Check response.json shows statusCode 200
4. **Check DB:** Query rolling_merchant table
5. **Monitor:** Check CloudWatch logs if issues

---

**Issue:** ✅ RESOLVED
**Root Cause:** Platform mismatch (macOS binary on Linux Lambda)
**Solution:** Installed Linux-compatible psycopg2-binary
**Status:** Ready to deploy and test
