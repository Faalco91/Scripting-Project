#!/bin/bash

# Module d'installation des solutions Dolibarr et GLPI
# Part 1 du projet - Installation


install_prerequisites() {
    echo "----- Début installation des prérequis -----"
    
    echo "Mise à jour de la liste des paquets.."
    apt update -y
    
    echo "Installation d'Apache2"
    apt install -y apache2
    
    systemctl enable apache2
    systemctl start apache2
    echo "Apache2 installé et démarré avec succès !"
    
    apt install -y php php-mysql php-gd php-curl php-xml php-zip \
            php-mbstring php-intl php-json php-ldap \
            php-cli php-common libapache2-mod-php

    if ! command -v php &> /dev/null; then
        echo "Erreur : PHP n'a pas pu être installé "
        return 1
    fi

    echo "PHP installé avec succès !"
    
    echo "Installation de MariaDB..."
    apt install -y mariadb-server mariadb-client
    
    systemctl enable mariadb
    systemctl start mariadb
    echo "MariaDB est installé et démarré avec succès !"
    
    a2enmod rewrite
    a2enmod ssl
    a2enmod headers
    
    systemctl restart apache2
    
    echo "----- L'installation des prérequis terminée :) -----"

}


create_databases() {
    echo "--- Création des bases de données pour Dolibarr et GLPI.. ---"
    
    DOLIBARR_DB="dolibarr_db"
    DOLIBARR_USER="dolibarr_user"
    DOLIBARR_PASS="password123"
    
    GLPI_DB="glpi_db"
    GLPI_USER="glpi_user"
    GLPI_PASS="password123"
    
    echo "Création de la base Dolibarr..."
    mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS $DOLIBARR_DB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DOLIBARR_USER'@'localhost' IDENTIFIED BY '$DOLIBARR_PASS';
GRANT ALL PRIVILEGES ON $DOLIBARR_DB.* TO '$DOLIBARR_USER'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    if [[ $? -ne 0 ]]; then
        echo "Erreur lors de la création de la base Dolibarr"
        return 1
    fi
    
    echo "Base Dolibarr créée avec succès !"
    
    echo "Création de la base GLPI..."
    mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS $GLPI_DB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$GLPI_USER'@'localhost' IDENTIFIED BY '$GLPI_PASS';
GRANT ALL PRIVILEGES ON $GLPI_DB.* TO '$GLPI_USER'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    if [[ $? -ne 0 ]]; then
        echo "Erreur lors de la création de la base GLPI"
        return 1
    fi
    
    echo "Base GLPI créer avec succès !"

    
    echo "--- Création des bases de données terminée :) ---"
}


install_dolibarr() {
    echo "--- Début d'installation de Dolibarr ---"
    
    DOLIBARR_VERSION="19.0.3"
    DOLIBARR_URL="https://github.com/Dolibarr/dolibarr/archive/refs/tags/${DOLIBARR_VERSION}.tar.gz"
    DOLIBARR_DIR="/var/www/html/dolibarr"
    TEMP_DIR="/tmp/dolibarr_install"
    
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    echo "Téléchargement de Dolibarr ${DOLIBARR_VERSION}..."
    wget -q --show-progress "$DOLIBARR_URL" -O "dolibarr-${DOLIBARR_VERSION}.tar.gz"
    
    if [[ $? -ne 0 ]]; then
        echo "Erreur lors du téléchargement de Dolibarr"
        return 1
    fi
    
    tar -xzf "dolibarr-${DOLIBARR_VERSION}.tar.gz"
    
    if [[ -d "$DOLIBARR_DIR" ]]; then
        echo "Suppression de l'ancienne installation..."
        rm -rf "$DOLIBARR_DIR"
    fi
    
    mv "dolibarr-${DOLIBARR_VERSION}/htdocs" "$DOLIBARR_DIR"
    
    mkdir -p "$DOLIBARR_DIR/documents"
    
    chown -R www-data:www-data "$DOLIBARR_DIR"
    chmod -R 755 "$DOLIBARR_DIR"
    chmod -R 775 "$DOLIBARR_DIR/documents"
    
    cat > /etc/apache2/sites-available/dolibarr.conf <<'EOF'
<VirtualHost *:80>
    ServerName dolibarr.local
    
    Alias /dolibarr /var/www/html/dolibarr
    
    <Directory /var/www/html/dolibarr>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog ${APACHE_LOG_DIR}/dolibarr_error.log
    CustomLog ${APACHE_LOG_DIR}/dolibarr_access.log combined
</VirtualHost>
EOF
    
    a2ensite dolibarr.conf
    systemctl reload apache2
    
    cd /
    rm -rf "$TEMP_DIR"
    
    echo "--- Installation Dolibarr terminée :) ---"
    echo "  Vous pouvez accéder à Dolibarr via l'URL suivante: http://localhost/dolibarr"
}


install_glpi() {
    echo "--- Début d'installation de GLPI ---"
    
    GLPI_VERSION="11.0.2"
    GLPI_URL="https://github.com/glpi-project/glpi/releases/download/${GLPI_VERSION}/glpi-${GLPI_VERSION}.tgz"
    GLPI_DIR="/var/www/html/glpi"
    TEMP_DIR="/tmp/glpi_install"
    
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    echo "Téléchargement de GLPI ${GLPI_VERSION}..."
    wget -q --show-progress "$GLPI_URL" -O "glpi-${GLPI_VERSION}.tgz"
    
    if [ $? -ne 0 ]; then
        echo "Erreur lors du téléchargement de GLPI"
        return 1
    fi
    
    tar -xzf "glpi-${GLPI_VERSION}.tgz"
    
    if [ -d "$GLPI_DIR" ]; then
        echo "Suppression de l'ancienne installation..."
        rm -rf "$GLPI_DIR"
    fi
    
    mv glpi "$GLPI_DIR"
    
    chown -R www-data:www-data "$GLPI_DIR"
    chmod -R 755 "$GLPI_DIR"
    chmod -R 775 "$GLPI_DIR/files"
    chmod -R 775 "$GLPI_DIR/config"
    
    cat > /etc/apache2/sites-available/glpi.conf <<'EOF'
<VirtualHost *:80>
    ServerName glpi.local
    
    Alias /glpi /var/www/html/glpi/public
    
    <Directory /var/www/html/glpi/public>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
        
        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteRule ^(.*)$ index.php [QSA,L]
    </Directory>
    
    ErrorLog ${APACHE_LOG_DIR}/glpi_error.log
    CustomLog ${APACHE_LOG_DIR}/glpi_access.log combined
</VirtualHost>
EOF
    
    a2ensite glpi.conf
    systemctl reload apache2
    
    cd /
    rm -rf "$TEMP_DIR"
    
    echo "--- Installation GLPI terminée :) ---"
    echo "  Vous pouvez accéder à GLPI via l'URL suivante: http://localhost/glpi"
}