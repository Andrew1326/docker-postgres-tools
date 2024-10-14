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
  docker exec -e PGPASSWORD=$DB_PASSWORD $CONTAINER_NAME psql -U $DB_USER -d postgres -c "$sql_command"
}

# Terminate all active connections to the database
terminate_connections="SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = '$DB_NAME'
AND pid <> pg_backend_pid();"

execute_sql "$terminate_connections"

# Wait for a moment to ensure all connections are terminated
sleep 2

# Drop all schemas except the default ones ('pg_catalog', 'information_schema')
drop_schemas="DO \$\$ DECLARE r RECORD;
BEGIN
    FOR r IN (SELECT nspname FROM pg_namespace WHERE nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')) LOOP
        EXECUTE 'DROP SCHEMA IF EXISTS ' || quote_ident(r.nspname) || ' CASCADE';
    END LOOP;
END \$\$;"

execute_sql "$drop_schemas"

# Wait for a moment to ensure schemas are dropped
sleep 2

# Drop the database
drop_database="DROP DATABASE IF EXISTS $DB_NAME;"
execute_sql "$drop_database"

# Check if the database was deleted successfully
if [ $? -eq 0 ]; then
  echo "Database '$DB_NAME' and all schemas deleted successfully."
else
  echo "Failed to delete database '$DB_NAME'."
fi

# Remove any roles (users) associated with the database
drop_roles="DO \$\$ DECLARE r RECORD;
BEGIN
    FOR r IN (SELECT rolname FROM pg_roles WHERE rolname <> 'postgres' AND rolname <> 'pg_signal_backend') LOOP
        EXECUTE 'DROP ROLE IF EXISTS ' || quote_ident(r.rolname) || ' CASCADE';
    END LOOP;
END \$\$;"

execute_sql "$drop_roles"

echo "All related roles have been deleted."

read -p "Press any key to exit."
