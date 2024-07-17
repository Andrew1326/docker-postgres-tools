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

# Terminate all active connections to the database
terminate_connections="SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = '$DB_NAME'
AND pid <> pg_backend_pid();"

execute_sql "$terminate_connections"

# Wait for a moment to ensure all connections are terminated
sleep 2

# Drop the database
drop_database="DROP DATABASE IF EXISTS $DB_NAME;"
execute_sql "$drop_database"

# Check if the database was deleted successfully
if [ $? -eq 0 ]; then
  echo "Database '$DB_NAME' deleted successfully."
else
  echo "Failed to delete database '$DB_NAME'."
fi