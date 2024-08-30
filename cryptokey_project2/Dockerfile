# Utiliser l'image officielle de Python comme base
FROM python:3.10-slim

# Définir le répertoire de travail dans le conteneur
WORKDIR /app

# Mettre à jour les sources de paquets et installer les dépendances système
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        libpq-dev \
        gcc \
    && rm -rf /var/lib/apt/lists/*

# Copier et installer les dépendances Python
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copier le projet Django dans le conteneur
COPY . /app/

# Copier le script d'entrée
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Exposer le port 8000 (port par défaut de Django)
EXPOSE 8000

# Utiliser le script d'entrée par défaut
ENTRYPOINT ["/app/entrypoint.sh"]

# Lancer le serveur de développement Django
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
