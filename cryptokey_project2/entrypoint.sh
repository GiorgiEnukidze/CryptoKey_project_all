#!/bin/sh

# Attendre que la base de données soit prête
/app/wait_for_db.sh

# Appliquer les migrations
python manage.py migrate

python manage.py makemigrations
python manage.py migrate

# Créer un superutilisateur si nécessaire
if [ "$DJANGO_SUPERUSER_USERNAME" ] && [ "$DJANGO_SUPERUSER_PASSWORD" ] && [ "$DJANGO_SUPERUSER_EMAIL" ]; then
  python manage.py createsuperuser --no-input || true
fi

# Lancer le serveur de développement Django
exec "$@"
