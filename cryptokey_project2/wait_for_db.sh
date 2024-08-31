#!/bin/bash
# wait_for_db.sh

set -e

host="${POSTGRES_HOST:-db}"   # Use POSTGRES_HOST, default to 'db'
user="${POSTGRES_USER:-postgres}"  # Default user to 'postgres' if not set
password="${POSTGRES_PASSWORD}"
db="${POSTGRES_DB:-postgres}"  # Default DB to 'postgres' if not set

until PGPASSWORD=$password psql -h "$host" -U "$user" -d "$db" -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

>&2 echo "Postgres is up - executing command"
exec "$@"
