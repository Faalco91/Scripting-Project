#!/bin/bash


configure_hosts() {
    echo "--- Configuration /etc/hosts ---"
    
    if grep -q "dolibarr.local" /etc/hosts && grep -q "glpi.local" /etc/hosts; then
        echo "Les entrées existent déjà dans /etc/hosts"
        return 0
    fi
    
    echo "Ajout des entrées dolibarr.local et glpi.local..."
    echo "127.0.0.1   dolibarr.local" >> /etc/hosts
    echo "127.0.0.1   glpi.local" >> /etc/hosts
    
    echo "Configuration /etc/hosts terminée"
}

restart_services() {
    echo "--- Redémarrage des services ---"
    
    echo "Redémarrage Apache..."
    systemctl restart apache2
    if [ $? -eq 0 ]; then
        echo "Apache redémarré avec succès"
    else
        echo "Erreur lors du redémarrage d'Apache"
        return 1
    fi
    
    echo "Redémarrage MariaDB..."
    systemctl restart mariadb
    if [ $? -eq 0 ]; then
        echo "MariaDB redémarré avec succès"
    else
        echo "Erreur lors du redémarrage de MariaDB"
        return 1
    fi
    
    echo "Tous les services sont redémarrés"
}
