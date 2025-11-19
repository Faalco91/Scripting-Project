# Cette Fonction va permettre d'installer Apache2, PHP, MariaDB (autrement dis les prerequis de base) et toutes les extensions nécessaires

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


