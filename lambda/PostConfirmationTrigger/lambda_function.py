"""
Lambda function to create user profile in PostgreSQL database
Triggered by Cognito Post-Confirmation event
Works with existing schema: users(user_id, username, email, password_hash, phone_number, created_at)
"""

import json
import os
import pg8000

def lambda_handler(event, context):
    """
    Cognito Post-Confirmation Trigger
    Creates user profile in database after successful email confirmation
    """
    
    print(f"Received event: {json.dumps(event)}")
    
    # Extract user attributes from Cognito event
    user_attributes = event['request']['userAttributes']
    cognito_sub = event['userName']  # Cognito user's unique ID (sub)
    email = user_attributes.get('email')
    first_name = user_attributes.get('given_name', '')
    last_name = user_attributes.get('family_name', '')
    
    # Create username - store Cognito sub with prefix so we can look it up later
    # Format: "cognito:abc123def456" where abc123def456 is the Cognito sub
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
        
        # Check if user already exists by email
        check_query = "SELECT user_id, username FROM users WHERE email = %s"
        cursor.execute(check_query, (email,))
        existing_user = cursor.fetchone()
        
        if existing_user:
            user_id, existing_username = existing_user
            # Update username to store Cognito sub if it doesn't already
            if not existing_username.startswith('cognito:'):
                update_query = "UPDATE users SET username = %s WHERE user_id = %s"
                cursor.execute(update_query, (cognito_username, user_id))
                conn.commit()
                print(f"✅ Updated existing user {email} with Cognito ID")
            else:
                print(f"ℹ️ User {email} already has Cognito ID stored")
        else:
            # Insert new user profile
            insert_query = """
                INSERT INTO users (
                    username, 
                    email, 
                    password_hash, 
                    phone_number
                )
                VALUES (%s, %s, %s, %s)
            """
            
            cursor.execute(insert_query, (
                cognito_username,      # username = "cognito:{sub}"
                email,                 # email from Cognito
                'COGNITO_MANAGED',     # password_hash = placeholder (Cognito manages passwords)
                None                   # phone_number = NULL for now
            ))
            conn.commit()
            
            print(f"✅ Created new user profile for {email}")
        
        cursor.close()
        conn.close()
        
    except Exception as e:
        print(f"❌ Error creating user profile: {str(e)}")
        import traceback
        print(traceback.format_exc())
        # Don't fail the Cognito confirmation - just log the error
        # User can still sign in, profile will be created on first API call
    
    # IMPORTANT: Return the event unchanged for Cognito
    return event
