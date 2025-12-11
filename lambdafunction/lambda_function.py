import json
import pg8000
import os
import hashlib
from datetime import datetime, timezone
from mcc_directory import load_mcc_directory, find_mcc_for_merchant_name
from normalization import normalize_poi_name

# Load MCC data on cold start
load_mcc_directory()

def lambda_handler(event, context):
    """
    Lambda handler for merchant data processing and RDS write.
    
    Expected input:
    {
        "userId": 1,                    # BIGINT - from users table (required)
        "generationId": "uuid-string",  # UUID - for this set of merchants (required)
        "merchantName": "STARBUCKS COFFEE",
        "latitude": 37.3382,
        "longitude": -122.0309
    }
    """
    try:
        # Parse input
        body = json.loads(event.get('body', '{}')) if isinstance(event.get('body'), str) else event
        
        user_id = body.get('userId')
        generation_id = body.get('generationId')
        merchant_name = body.get('merchantName')
        latitude = body.get('latitude')
        longitude = body.get('longitude')
        
        # Validate required fields
        if not all([user_id is not None, generation_id, merchant_name, latitude, longitude]):
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Missing required fields: userId, generationId, merchantName, latitude, longitude'
                })
            }
        
        # Validate user_id is numeric
        try:
            user_id_int = int(user_id)
            if user_id_int <= 0:
                raise ValueError("user_id must be positive")
        except (ValueError, TypeError):
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': f'userId must be a valid positive integer (got: {user_id})'
                })
            }
        
        # Step 1: Normalize merchant name
        generalized_name = normalize_poi_name(merchant_name)
        print(f"✅ Normalized '{merchant_name}' → '{generalized_name}'")
        
        # Step 2: Match generalized name to MCC + category_key
        mcc_data = find_mcc_for_merchant_name(generalized_name)
        mcc = mcc_data.get('mcc')
        category_key = mcc_data.get('categoryKey')
        
        print(f"✅ Matched to MCC: {mcc}, Category: {category_key}")
        
        # Step 3: Generate merchant_hash (only thing we generate)
        merchant_hash = hashlib.md5(generalized_name.encode()).hexdigest()
        
        # Step 4: Write to RDS rolling_merchant table
        write_to_rolling_merchant(
            user_id=user_id_int,
            generation_id=generation_id,
            merchant_hash=merchant_hash,
            raw_poi_name=merchant_name,
            generalized_name=generalized_name,
            mcc=mcc,
            category_key=category_key,
            lat=latitude,
            lon=longitude
        )
        
        print(f"✅ Written to DB: user_id={user_id_int}, generation_id={generation_id}, merchant_hash={merchant_hash}")
        
        # Return success
        return {
            'statusCode': 200,
            'body': json.dumps({
                'userId': user_id_int,
                'generationId': generation_id,
                'merchantHash': merchant_hash,
                'merchantName': generalized_name,
                'mcc': mcc,
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


def write_to_rolling_merchant(user_id, generation_id, merchant_hash, raw_poi_name, 
                               generalized_name, mcc, category_key, lat, lon):
    """
    Write merchant data to rolling_merchant table in RDS.
    
    Schema columns: user_id, generation_id, merchant_hash, raw_poi_name, 
                    generalized_name, category_key, mcc, lat, lon, detected_at
    
    Note: user_id must exist in users table (foreign key constraint)
          generation_id is managed by the caller (not generated here)
    """
    connection = None
    try:
        # Connect to RDS PostgreSQL using pg8000
        connection = pg8000.connect(
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
            (user_id, generation_id, merchant_hash, raw_poi_name, generalized_name, 
             category_key, mcc, lat, lon, detected_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        
        cursor.execute(insert_query, (
            user_id,
            generation_id,
            merchant_hash,
            raw_poi_name,
            generalized_name,
            category_key,
            mcc,
            lat,
            lon,
            datetime.now(timezone.utc)
        ))
        
        connection.commit()
        
    except Exception as e:
        error_msg = str(e)
        if 'foreign key constraint' in error_msg and 'user_id' in error_msg:
            print(f"❌ Foreign key error: user_id {user_id} does not exist in users table")
            raise Exception(f"user_id {user_id} does not exist in users table. User must be created first.")
        print(f"Database error: {e}")
        if connection:
            connection.rollback()
        raise
    
    finally:
        if connection:
            cursor.close()
            connection.close()
