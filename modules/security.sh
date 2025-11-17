#!/bin/bash

create_ca() {
    echo "--- Création de la CA ---"
    
    mkdir -p /etc/ssl/ca
    
    if [ -f /etc/ssl/ca/ca-cert.pem ]; then
        echo "Attention: une CA existe déjà"
        read -p "Voulez-vous la recréer ? (o/n) " choix
        if [ "$choix" != "o" ]; then
            echo "OK, on garde l'ancienne CA"
            return 0
        fi
    fi
    
    echo "Génération de la clé privée..."
    openssl genpkey -algorithm RSA -out /etc/ssl/ca/ca-key.pem -pkeyopt rsa_keygen_bits:4096 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "OK - Clé générée"
        chmod 600 /etc/ssl/ca/ca-key.pem
    else
        echo "Erreur lors de la génération de la clé"
        return 1
    fi
    
    echo "Création du certificat CA..."
    openssl req -new -x509 -nodes -key /etc/ssl/ca/ca-key.pem -sha256 -out /etc/ssl/ca/ca-cert.pem -days 3650 \
        -subj "/C=FR/ST=IDF/L=Paris/O=Entreprise/OU=IT/CN=Root-CA" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "OK - Certificat CA créé"
        chmod 644 /etc/ssl/ca/ca-cert.pem
    else
        echo "Erreur lors de la création du certificat"
        return 1
    fi
    
    echo "1000" > /etc/ssl/ca/serial
    
    echo ""
    echo "=== CA créée avec succès ==="
    echo "Fichiers générés:"
    echo "  - Clé privée: /etc/ssl/ca/ca-key.pem"
    echo "  - Certificat: /etc/ssl/ca/ca-cert.pem"
    echo ""
    
    openssl x509 -in /etc/ssl/ca/ca-cert.pem -noout -subject -dates 2>/dev/null
    echo ""
}
