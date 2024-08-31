#!/bin/bash
# wait_for_db.sh

set -e

host="$DB_HOST"
user="$POSTGRES_USER"
password="$POSTGRES_PASSWORD"
db="$POSTGRES_DB"

until PGPASSWORD=$password psql -h "$host" -U "$user" -d "$db" -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

>&2 echo "Postgres is up - executing command"
exec "$@"
