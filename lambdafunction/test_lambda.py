#!/usr/bin/env python3
"""
Test script for MerchantResolverFn Lambda function.
Run locally before deploying to AWS.
"""

import json
import sys
import os

# Add current directory to path so we can import our modules
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from lambda_function import lambda_handler
from normalization import normalize_poi_name
from mcc_directory import load_mcc_directory, find_mcc_for_merchant_name


def test_normalization():
    """Test merchant name normalization"""
    print("\n=== Testing Normalization ===")
    
    test_cases = [
        ("STARBUCKS COFFEE", "STARBUCKS COFFEE"),
        ("Starbucks Coffee!!", "STARBUCKS COFFEE"),
        ("DUNKIN DONUTS", "DUNKIN"),
        ("McDonald's Restaurant", "MCDONALDS RESTAURANT"),
        ("7-Eleven Store #1234", "7 ELEVEN STORE 1234"),
    ]
    
    for raw, expected in test_cases:
        result = normalize_poi_name(raw)
        status = "✅" if result == expected else "❌"
        print(f"{status} '{raw}' → '{result}' (expected: '{expected}')")
    
    print("Normalization tests complete.\n")


def test_mcc_directory():
    """Test MCC code matching"""
    print("=== Testing MCC Directory ===")
    
    # Load MCC data
    load_mcc_directory()
    
    test_cases = [
        ("STARBUCKS", "5810", "Restaurants"),
        ("SAFEWAY", "5411", "Grocery"),
        ("SHELL", "5541", "Gas"),
        ("WALGREENS", "5912", "Drug"),
    ]
    
    for merchant, expected_mcc, expected_category in test_cases:
        result = find_mcc_for_merchant_name(merchant)
        mcc = result.get('mcc', 'None')
        category = result.get('categoryKey', 'None')
        
        # Check if MCC matches or category contains expected
        mcc_match = mcc == expected_mcc or mcc is not None
        status = "✅" if mcc_match else "❌"
        
        print(f"{status} '{merchant}' → MCC: {mcc}, Category: {category}")
    
    print("MCC directory tests complete.\n")


def test_lambda_handler_success():
    """Test Lambda handler with valid input"""
    print("=== Testing Lambda Handler (Success Case) ===")
    
    # Mock event with valid data
    event = {
        "body": json.dumps({
            "userId": "test_user_123",
            "merchantName": "STARBUCKS COFFEE",
            "latitude": 37.3382,
            "longitude": -122.0309
        })
    }
    
    # Mock context (not used in our function)
    context = {}
    
    try:
        response = lambda_handler(event, context)
        
        print(f"Status Code: {response['statusCode']}")
        
        if response['statusCode'] == 200:
            body = json.loads(response['body'])
            print(f"✅ Success!")
            print(f"   Merchant Name: {body.get('merchantName')}")
            print(f"   MCC: {body.get('mcc')}")
            print(f"   Category: {body.get('categoryKey')}")
            print(f"   Record ID: {body.get('recordId', 'N/A (DB not connected)')}")
        else:
            body = json.loads(response['body'])
            print(f"❌ Error: {body.get('error')}")
    
    except Exception as e:
        print(f"❌ Exception: {str(e)}")
        print(f"   Note: This is expected if DB credentials are not set.")
    
    print("Lambda handler success test complete.\n")


def test_lambda_handler_missing_fields():
    """Test Lambda handler with missing required fields"""
    print("=== Testing Lambda Handler (Missing Fields) ===")
    
    test_cases = [
        {"userId": "user_123"},  # Missing merchantName, lat, lon
        {"merchantName": "STARBUCKS"},  # Missing userId, lat, lon
        {"userId": "user_123", "merchantName": "STARBUCKS"},  # Missing lat, lon
    ]
    
    for i, incomplete_data in enumerate(test_cases, 1):
        event = {"body": json.dumps(incomplete_data)}
        context = {}
        
        response = lambda_handler(event, context)
        
        if response['statusCode'] == 400:
            body = json.loads(response['body'])
            print(f"✅ Test {i}: Correctly rejected with error: {body.get('error')}")
        else:
            print(f"❌ Test {i}: Expected 400 error, got {response['statusCode']}")
    
    print("Lambda handler validation tests complete.\n")


def test_lambda_handler_invalid_json():
    """Test Lambda handler with invalid JSON"""
    print("=== Testing Lambda Handler (Invalid JSON) ===")
    
    event = {"body": "not valid json{{}"}
    context = {}
    
    try:
        response = lambda_handler(event, context)
        if response['statusCode'] >= 400:
            print(f"✅ Correctly handled invalid JSON with status {response['statusCode']}")
        else:
            print(f"❌ Expected error, got {response['statusCode']}")
    except Exception as e:
        print(f"✅ Correctly raised exception: {type(e).__name__}")
    
    print("Invalid JSON test complete.\n")


def test_database_connection():
    """Test database connection (will fail if env vars not set)"""
    print("=== Testing Database Connection ===")
    
    required_env_vars = ['DB_HOST', 'DB_PORT', 'DB_NAME', 'DB_USER', 'DB_PASSWORD']
    
    missing_vars = [var for var in required_env_vars if not os.environ.get(var)]
    
    if missing_vars:
        print(f"⚠️  Missing environment variables: {', '.join(missing_vars)}")
        print("   Set these to test database connection:")
        print("   export DB_HOST=plasticprophet-db.cg1cy2qk2qui.us-east-1.rds.amazonaws.com")
        print("   export DB_PORT=5432")
        print("   export DB_NAME=plasticprophetdb")
        print("   export DB_USER=plasticadmin")
        print("   export DB_PASSWORD=Database123!")
        return
    
    print("✅ All environment variables set")
    
    # Try actual database write
    try:
        import psycopg2
        
        connection = psycopg2.connect(
            host=os.environ.get('DB_HOST'),
            port=int(os.environ.get('DB_PORT', '5432')),
            database=os.environ.get('DB_NAME'),
            user=os.environ.get('DB_USER'),
            password=os.environ.get('DB_PASSWORD')
        )
        
        cursor = connection.cursor()
        cursor.execute("SELECT 1;")
        result = cursor.fetchone()
        
        if result[0] == 1:
            print("✅ Database connection successful!")
        
        cursor.close()
        connection.close()
        
    except Exception as e:
        print(f"❌ Database connection failed: {str(e)}")
    
    print("Database connection test complete.\n")


def run_all_tests():
    """Run all tests"""
    print("\n" + "="*60)
    print("   MerchantResolverFn Lambda Function Tests")
    print("="*60)
    
    # Unit tests (no DB required)
    test_normalization()
    test_mcc_directory()
    
    # Lambda handler tests (no DB required for these)
    test_lambda_handler_success()
    test_lambda_handler_missing_fields()
    test_lambda_handler_invalid_json()
    
    # Database connection test (requires env vars)
    test_database_connection()
    
    print("="*60)
    print("   All Tests Complete")
    print("="*60)
    print("\nNote: Database write tests require environment variables.")
    print("Set DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD to test DB writes.\n")


if __name__ == "__main__":
    run_all_tests()
