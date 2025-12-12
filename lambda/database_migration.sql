-- Migration script to add Cognito integration to existing users table
-- Run this on your PostgreSQL database before deploying Lambda functions

-- Add cognito_user_id column (unique identifier from Cognito)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS cognito_user_id VARCHAR(255) UNIQUE;

-- Add first_name and last_name columns for better user profiles
ALTER TABLE users
ADD COLUMN IF NOT EXISTS first_name VARCHAR(100),
ADD COLUMN IF NOT EXISTS last_name VARCHAR(100);

-- Create index for faster Cognito user lookups
CREATE INDEX IF NOT EXISTS users_cognito_idx ON users(cognito_user_id);

-- Optional: Make password_hash nullable since Cognito users won't have one
ALTER TABLE users 
ALTER COLUMN password_hash DROP NOT NULL;

-- Note: Existing users will have NULL cognito_user_id
-- Only new users created via Cognito will have this populated
