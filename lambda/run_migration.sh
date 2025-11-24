#!/bin/bash

# Quick script to apply database migration
# Replace with your actual database connection details

export DB_ENDPOINT="proxy-1762399671009-plasticprophet-db.proxy-cg1cy2qk2qui.us-east-1.rds.amazonaws.com"
export DB_NAME="plasticprophet"
export DB_USER="plasticadmin"
export DB_PASSWORD="Database123!"

echo "🔧 Applying database migration..."
echo "This will add cognito_user_id, first_name, and last_name columns to the users table"
echo ""

# You'll need to run this from an EC2 instance in the same VPC, or enable temporary public access
# Uncomment the method you want to use:

# Method 1: If you have psql installed and can connect
# psql -h $DB_ENDPOINT -U $DB_USER -d $DB_NAME -f database_migration.sql

# Method 2: Copy the SQL and paste it manually in AWS RDS Query Editor
echo "Copy this SQL and run it in AWS RDS Query Editor:"
echo "=========================================="
cat database_migration.sql
echo "=========================================="
echo ""
echo "Or connect via psql:"
echo "psql -h $DB_ENDPOINT -U $DB_USER -d $DB_NAME -f database_migration.sql"
