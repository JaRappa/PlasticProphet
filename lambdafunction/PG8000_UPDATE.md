import json
import psycopg2
import os
import re
from datetime import datetime
from mcc_directory import load_mcc_directory, find_mcc_for_merchant_name
from normalization import normalize_poi_name

# Load MCC data on cold start
load_mcc_directory()

def lambda_handler(event, context):
    """
    Lambda handler for merchant data processing and RDS write.
    
    Expected input:
    {
        "userId": "user_123",
        "merchantName": "STARBUCKS COFFEE",
        "latitude": 37.3382,
        "longitude": -122.0309
    }
    """
    try:
        # Parse input
        body = json.loads(event.get('body', '{}')) if isinstance(event.get('body'), str) else event
        
        user_id = body.get('userId')
        merchant_name = body.get('merchantName')
        latitude = body.get('latitude')
        longitude = body.get('longitude')
        
        # Validate required fields
        if not all([user_id, merchant_name, latitude, longitude]):
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Missing required fields: userId, merchantName, latitude, longitude'
                })
            }
        
        # Step 1: Normalize merchant name
        generalized_name = normalize_poi_name(merchant_name)
        print(f"✅ Normalized '{merchant_name}' → '{generalized_name}'")
        
        # Step 2: Match generalized name to MCC + category_key
        mcc_data = find_mcc_for_merchant_name(generalized_name)
        mcc_code = mcc_data.get('mcc')
        category_key = mcc_data.get('categoryKey')
        
        print(f"✅ Matched to MCC: {mcc_code}, Category: {category_key}")
        
        # Step 3: Write to RDS rolling_merchant table
        record_id = write_to_rolling_merchant(
            user_id=user_id,
            generalized_name=generalized_name,
            mcc_code=mcc_code,
            category_key=category_key,
            latitude=latitude,
            longitude=longitude
        )
        
        print(f"✅ Written to DB with record ID: {record_id}")
        
        # Return success
        return {
            'statusCode': 200,
            'body': json.dumps({
                'recordId': record_id,
                'merchantName': generalized_name,
                'mcc': mcc_code,
                'categoryKey': category_key,
                'message': 'Successfully processed merchant data'
            })
        }
    
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }


def write_to_rolling_merchant(user_id, generalized_name, mcc_code, category_key, latitude, longitude):
    """
    Write merchant data to rolling_merchant table in RDS.
    """
    connection = None
    try:
        # Connect to RDS PostgreSQL
        connection = psycopg2.connect(
            host=os.environ.get('DB_HOST'),
            port=int(os.environ.get('DB_PORT', '5432')),
            database=os.environ.get('DB_NAME'),
            user=os.environ.get('DB_USER'),
            password=os.environ.get('DB_PASSWORD')
        )
        
        cursor = connection.cursor()
        
        # Insert into rolling_merchant table
        insert_query = """
            INSERT INTO rolling_merchant 
            (user_id, generalized_name, mcc_code, category_key, latitude, longitude, detected_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING id;
        """
        
        cursor.execute(insert_query, (
            user_id,
            generalized_name,
            mcc_code,
            category_key,
            latitude,
            longitude,
            datetime.utcnow()
        ))
        
        record_id = cursor.fetchone()[0]
        connection.commit()
        
        return record_id
    
    except psycopg2.Error as e:
        print(f"Database error: {e}")
        if connection:
            connection.rollback()
        raise
    
    finally:
        if connection:
            cursor.close()
            connection.close()
