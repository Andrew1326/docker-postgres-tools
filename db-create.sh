#!/bin/bash

# Source the configuration file
source ./db-config.sh

# Check if necessary variables are provided
if [ -z "$CONTAINER_NAME" ] || [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ]; then
  echo "Error: One or more variables are not set."
  echo "Please set CONTAINER_NAME, DB_NAME, DB_USER, and DB_PASSWORD."
  exit 1
fi

# Function to execute SQL commands inside the Docker container
execute_sql() {
  local sql_command=$1
  docker exec -e PGPASSWORD=$DB_PASSWORD $CONTAINER_NAME psql -U $DB_USER -c "$sql_command"
}

# Create the database
create_database="CREATE DATABASE $DB_NAME;"
execute_sql "$create_database"

# Check if the database was created successfully
if [ $? -eq 0 ]; then
  echo "Database '$DB_NAME' created successfully."
else
  echo "Failed to create database '$DB_NAME'."
fi

read -p "Press any key to exit."