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

generate_dolibarr_cert() {
    echo "--- Génération certificat Dolibarr ---"
    
    mkdir -p /etc/ssl/dolibarr
    
    echo "Génération de la clé privée Dolibarr..."
    openssl genpkey -algorithm RSA -out /etc/ssl/dolibarr/dolibarr.key -pkeyopt rsa_keygen_bits:4096 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "OK - Clé Dolibarr générée"
        chmod 600 /etc/ssl/dolibarr/dolibarr.key
    else
        echo "Erreur lors de la génération de la clé"
        return 1
    fi
    
    echo "Création du fichier de configuration SAN..."
    cat > /etc/ssl/dolibarr/dolibarr.cnf <<EOF
[req]
default_bits = 4096
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[dn]
C=FR
ST=IDF
L=Paris
O=Entreprise
OU=IT
CN=dolibarr.local

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = dolibarr.local
DNS.2 = www.dolibarr.local
IP.1 = 127.0.0.1
EOF
    
    echo "Création de la demande de certificat (CSR)..."
    openssl req -new -key /etc/ssl/dolibarr/dolibarr.key -out /etc/ssl/dolibarr/dolibarr.csr -config /etc/ssl/dolibarr/dolibarr.cnf 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "OK - CSR créé"
    else
        echo "Erreur lors de la création du CSR"
        return 1
    fi
    
    echo "Signature du certificat par la CA..."
    openssl x509 -req -in /etc/ssl/dolibarr/dolibarr.csr -CA /etc/ssl/ca/ca-cert.pem -CAkey /etc/ssl/ca/ca-key.pem -CAserial /etc/ssl/ca/serial -out /etc/ssl/dolibarr/dolibarr.crt -days 365 -sha256 -extensions v3_req -extfile /etc/ssl/dolibarr/dolibarr.cnf 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "OK - Certificat Dolibarr signé"
        chmod 644 /etc/ssl/dolibarr/dolibarr.crt
    else
        echo "Erreur lors de la signature du certificat"
        return 1
    fi
    
    echo ""
    echo "=== Certificat Dolibarr créé ==="
    echo "Fichiers générés:"
    echo "  - Clé privée: /etc/ssl/dolibarr/dolibarr.key"
    echo "  - CSR: /etc/ssl/dolibarr/dolibarr.csr"
    echo "  - Certificat: /etc/ssl/dolibarr/dolibarr.crt"
    echo ""
    
    openssl x509 -in /etc/ssl/dolibarr/dolibarr.crt -noout -subject -dates -ext subjectAltName 2>/dev/null
    echo ""
}
