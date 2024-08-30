# Étape 1 : Préparation de l'environnement de base
FROM debian:bullseye-slim AS base

# Installation des dépendances nécessaires
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    git \
    curl \
    xz-utils \
    ca-certificates \
    && apt-get clean

# Télécharger et installer Flutter SDK (version 3.24.0)
RUN wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz \
    && tar xf flutter_linux_3.24.0-stable.tar.xz -C /opt \
    && rm flutter_linux_3.24.0-stable.tar.xz

# Configuration de git pour éviter les erreurs de permission
RUN git config --global --add safe.directory /opt/flutter

# Ajouter un utilisateur non-root pour l'exécution de Flutter
RUN useradd -m -d /home/flutteruser flutteruser
USER flutteruser

# Ajout du chemin Flutter au PATH
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Étape 2 : Configuration et vérification de Flutter
FROM base AS flutter-setup

# Activer le support web dans Flutter
RUN flutter config --enable-web

# Vérifier l'installation de Flutter
RUN flutter doctor

# Étape 3 : Construction de l'application Flutter
FROM flutter-setup AS build

WORKDIR /app
COPY --chown=flutteruser:docker . /app

# Installer les dépendances de l'application Flutter
RUN flutter pub get --suppress-analytics

# Construire l'application Flutter pour le Web avec l'URL de l'API définie
ARG API_URL
RUN flutter build web --dart-define=API_URL=${API_URL} --suppress-analytics

# Étape 4 : Configuration du serveur Nginx pour servir l'application Flutter Web
FROM nginx:alpine

# Copier les fichiers construits depuis l'étape précédente
COPY --from=build /app/build/web /usr/share/nginx/html

# Exposer le port 80 pour Nginx
EXPOSE 80

# Démarrer Nginx pour servir l'application
CMD ["nginx", "-g", "daemon off;"]
