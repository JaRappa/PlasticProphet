"""
Local test script for MCCMatcherAPI Lambda function.
Run this to test the ChatGPT MCC matching locally before deploying to AWS.

Requirements:
    pip install httpx python-dotenv

Usage:
    1. Set your OpenAI API key: export OPENAI_API_KEY=sk-your-key
    2. Run: python test_mcc_matcher.py
"""

import os
import json
import sys

# Add the lambda function directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from lambda_function import lambda_handler, load_mcc_codes

# Test cases
TEST_CASES = [
    {
        "name": "Starbucks Coffee",
        "category": "Coffee Shop",
        "address": "123 Main St, San Francisco, CA"
    },
    {
        "name": "McDonald's",
        "category": "Fast Food",
        "address": "456 Oak Ave, Los Angeles, CA"
    },
    {
        "name": "Safeway",
        "category": "Grocery Store",
        "address": "789 Elm St, Seattle, WA"
    },
    {
        "name": "Shell Gas Station",
        "category": "Gas Station",
        "address": "321 Highway 101, Portland, OR"
    },
    {
        "name": "Best Buy",
        "category": "Electronics Store",
        "address": "555 Tech Blvd, Austin, TX"
    },
    {
        "name": "Olive Garden",
        "category": "Restaurant",
        "address": "888 Restaurant Row, Denver, CO"
    },
    {
        "name": "CVS Pharmacy",
        "category": "Pharmacy",
        "address": "222 Health St, Boston, MA"
    },
    {
        "name": "Home Depot",
        "category": "Home Improvement",
        "address": "999 Builder Ln, Phoenix, AZ"
    },
    {
        "name": "Some Random Local Store",
        "category": None,
        "address": "111 Unknown St, Somewhere, USA"
    }
]


def run_tests():
    """Run test cases against the Lambda function."""
    
    # Check for API key
    if not os.environ.get('OPENAI_API_KEY'):
        print("❌ Error: OPENAI_API_KEY environment variable not set")
        print("   Set it with: export OPENAI_API_KEY=sk-your-key")
        return
    
    print("=" * 60)
    print("MCC Matcher API - Local Test Suite")
    print("=" * 60)
    print()
    
    # Load MCC codes first
    load_mcc_codes()
    
    results = []
    
    for i, test_case in enumerate(TEST_CASES, 1):
        print(f"Test {i}/{len(TEST_CASES)}: {test_case['name']}")
        print("-" * 40)
        
        try:
            # Simulate Lambda event
            event = {
                "body": json.dumps(test_case)
            }
            
            # Call the handler
            response = lambda_handler(event, None)
            
            status_code = response.get('statusCode', 0)
            body = json.loads(response.get('body', '{}'))
            
            if status_code == 200:
                print(f"  ✅ MCC: {body.get('mcc')}")
                print(f"  📊 Confidence: {body.get('confidence')}")
                print(f"  📝 Description: {body.get('description')}")
                results.append({
                    "name": test_case['name'],
                    "success": True,
                    "mcc": body.get('mcc'),
                    "confidence": body.get('confidence')
                })
            else:
                print(f"  ❌ Error: {body.get('error')}")
                results.append({
                    "name": test_case['name'],
                    "success": False,
                    "error": body.get('error')
                })
                
        except Exception as e:
            print(f"  ❌ Exception: {str(e)}")
            results.append({
                "name": test_case['name'],
                "success": False,
                "error": str(e)
            })
        
        print()
    
    # Summary
    print("=" * 60)
    print("Summary")
    print("=" * 60)
    
    successful = sum(1 for r in results if r.get('success'))
    print(f"  Passed: {successful}/{len(results)}")
    print()
    
    print("Results:")
    for r in results:
        status = "✅" if r.get('success') else "❌"
        if r.get('success'):
            print(f"  {status} {r['name']}: MCC {r['mcc']} ({r['confidence']})")
        else:
            print(f"  {status} {r['name']}: {r.get('error', 'Unknown error')}")


if __name__ == "__main__":
    run_tests()
