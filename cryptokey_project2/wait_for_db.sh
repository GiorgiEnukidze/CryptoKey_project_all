#!/bin/sh

while ! nc -z db 5432; do
    echo "attente de postgresql"
    sleep 1
done 

exec "$@"