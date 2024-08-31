#!/bin/bash

# Script pour automatiser des scans de sécurité avec Nmap et Nikto

# Domaine ou IP cible
TARGET="cryptokey.lebourbier.be"

# Options pour Nmap
NMAP_OPTIONS="-A -T4 -p 1-65535"

# Fichier de sortie pour Nmap
NMAP_OUTPUT_FILE="nmap_scan_result.txt"

# Fichier de sortie pour Nikto
NIKTO_OUTPUT_FILE="nikto_scan_result.txt"

# Exécuter le scan Nmap
echo "Démarrage du scan Nmap sur $TARGET avec les options $NMAP_OPTIONS..."
nmap $NMAP_OPTIONS $TARGET -oN $NMAP_OUTPUT_FILE

# Vérifier si le scan Nmap a réussi
if [ $? -eq 0 ]; then
    echo "Scan Nmap terminé avec succès. Résultats sauvegardés dans $NMAP_OUTPUT_FILE"
else
    echo "Échec du scan Nmap."
    exit 1  # Quitter le script en cas d'échec du scan Nmap
fi

# Exécuter le scan Nikto
echo "Démarrage du scan Nikto sur $TARGET..."
nikto -h http://$TARGET -output $NIKTO_OUTPUT_FILE

# Vérifier si le scan Nikto a réussi
if [ $? -eq 0 ]; then
    echo "Scan Nikto terminé avec succès. Résultats sauvegardés dans $NIKTO_OUTPUT_FILE"
else
    echo "Échec du scan Nikto."
    exit 1  # Quitter le script en cas d'échec du scan Nikto
fi
