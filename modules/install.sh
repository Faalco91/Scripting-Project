# Cette fonction va permettre d'installer Apache2, PHP, MariaDB (autrement dis les prerequis de base) et toutes les extensions nécessaires

install_prerequisites() {
    echo "----- Début installation des prérequis -----"
    
    echo "Mise à jour de la liste des paquets.."
    apt update -y
    
    echo "Installation d'Apache2"
    apt install -y apache2
    
    # On verifie simplement si Apache est bien actif
    systemctl enable apache2
    systemctl start apache2
    echo "Apache2 installé et démarré"
    

    echo "Installation de PHP avec les extensions..."
    apt install -y php php-mysql php-gd php-curl php-xml php-zip \
            php-mbstring php-intl php-json php-ldap \
            php-cli php-common libapache2-mod-php

    # On verifie également si php est bien installé et activé
    if ! command -v php &> /dev/null; then
        echo "Erreur : PHP n'a pas pu être installé "
        return 1
    fi

    echo "PHP installé avec les extensions"
    
    # Installation MariaDB
    echo "Installation de MariaDB..."
    apt install -y mariadb-server mariadb-client
    
    # demarrage de MariaDB
    systemctl enable mariadb
    systemctl start mariadb
    echo "MariaDB a bien été installé et démarré"
    
    # activation des modules Apache necessaires
    echo "Activation des modules Apache..."
    a2enmod rewrite
    a2enmod ssl
    a2enmod headers
    
    # restart Apache pour prendre en compte les changements
    systemctl restart apache2
    
    echo "----- Installation des prérequis terminée -----"
    echo ""
    echo "Voici les versions installées:"
    apache2 -v | head -n 1
    echo "PHP : $(php -v | head -n 1)"
    echo "MariaDB : $(mysql --version)"
}

# Cette fonction sert à créer les bases de données pour Dolibarr et GLPI
create_databases() {
    echo "--- Création des bases de données pour Dolibarr et GLPI.. ---"
    
    # Variables pour Dolibarr
    DOLIBARR_DB="dolibarr_db"
    DOLIBARR_USER="dolibarr_user"
    DOLIBARR_PASS="password123"
    
    # Variables pour GLPI
    GLPI_DB="glpi_db"
    GLPI_USER="glpi_user"
    GLPI_PASS="password123"
    
    # Creation de la base Dolibarr
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
    
    echo "Base Dolibarr créée avec succès"
    echo "  - Database: $DOLIBARR_DB"
    echo "  - User: $DOLIBARR_USER"
    echo "  - Password: $DOLIBARR_PASS"
    echo ""
    
    # Creation de la base GLPI
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
    echo "  - Database: $GLPI_DB"
    echo "  - User: $GLPI_USER"
    echo "  - Password: $GLPI_PASS"
    echo ""
    
    echo "--- Création des bases de données terminée :) ---"
}


