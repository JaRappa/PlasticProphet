"""
Lambda function to retrieve user profile from PostgreSQL database
Connected to API Gateway with Cognito Authorizer
Works with existing schema: users(user_id, username, email, password_hash, phone_number, created_at)
"""

import json
import os
import pg8000

def lambda_handler(event, context):
    """
    GET /profile endpoint
    Returns user profile from database based on Cognito user ID from JWT token
    """
    
    print(f"Received event: {json.dumps(event)}")
    
    # Extract Cognito user ID from authorizer context
    try:
        # API Gateway puts Cognito claims in the authorizer context
        cognito_sub = event['requestContext']['authorizer']['claims']['sub']
        email = event['requestContext']['authorizer']['claims']['email']
    except KeyError as e:
        print(f"❌ Missing required claim: {str(e)}")
        return {
            'statusCode': 401,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': 'Unauthorized - missing user claims'})
        }
    
    # Create the username we use to store Cognito users
    cognito_username = f"cognito:{cognito_sub}"
    
    # Database connection parameters from environment variables
    db_host = os.environ['DB_HOST']
    db_name = os.environ['DB_NAME']
    db_user = os.environ['DB_USER']
    db_password = os.environ['DB_PASSWORD']
    db_port = int(os.environ.get('DB_PORT', '5432'))
    
    try:
        # Connect to PostgreSQL
        print(f"Connecting to database: {db_host}:{db_port}/{db_name}")
        conn = pg8000.connect(
            host=db_host,
            port=db_port,
            database=db_name,
            user=db_user,
            password=db_password
        )
        
        cursor = conn.cursor()
        
        # Query user profile - try by username first (where we store cognito:sub)
        select_query = """
            SELECT 
                user_id,
                username,
                email, 
                phone_number,
                created_at
            FROM users
            WHERE username = %s OR email = %s
        """
        
        cursor.execute(select_query, (cognito_username, email))
        row = cursor.fetchone()
        
        if not row:
            # User not found in database - create profile from Cognito data
            print(f"⚠️ User not found in database, creating profile for: {email}")
            
            insert_query = """
                INSERT INTO users (
                    username, 
                    email, 
                    password_hash,
                    phone_number
                )
                VALUES (%s, %s, %s, %s)
                RETURNING user_id, username, email, phone_number, created_at
            """
            
            cursor.execute(insert_query, (cognito_username, email, 'COGNITO_MANAGED', None))
            conn.commit()
            row = cursor.fetchone()
        
        # Build response matching Swift UserProfile struct
        profile = {
            'user_id': row[0],
            'cognito_user_id': cognito_sub,  # Send back the actual Cognito sub
            'username': row[1],
            'email': row[2],
            'phone_number': row[3],
            'created_at': row[4].isoformat() if row[4] else None
        }
        
        print(f"✅ Successfully retrieved profile for user: {email}")
        
        cursor.close()
        conn.close()
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(profile)
        }
        
    except Exception as e:
        print(f"❌ Error retrieving user profile: {str(e)}")
        import traceback
        print(traceback.format_exc())
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': f'Internal server error: {str(e)}'})
        }
