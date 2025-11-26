#!/bin/bash

source "$(dirname "$0")/modules/install.sh"
source "$(dirname "$0")/modules/security.sh"
source "$(dirname "$0")/modules/utils.sh"

echo "========================================"
echo "   DÉPLOIEMENT DOLIBARR & GLPI"
echo "========================================"
echo ""

install_prerequisites
create_databases
install_dolibarr
install_glpi

echo ""
echo "========================================"
echo "   CONFIGURATION SÉCURITÉ SSL/TLS"
echo "========================================"
echo ""

create_ca
generate_dolibarr_cert
generate_glpi_cert
configure_apache_ssl
export_ca_certificate

echo ""
echo "========================================"
echo "   AUTHENTIFICATION PAGE DÉFAUT"
echo "========================================"
echo ""

setup_basic_auth

echo ""
echo "========================================"
echo "   FINALISATION"
echo "========================================"
echo ""

configure_hosts
restart_services

echo ""
echo "========================================"
echo "   DÉPLOIEMENT TERMINÉ !"
echo "========================================"
echo ""
echo "📋 Résumé des accès :"
echo "  - https://dolibarr.local (certificat SSL)"
echo "  - https://glpi.local (certificat SSL)"
echo "  - http://localhost/ca-cert/ (télécharger le certificat CA)"
echo ""
echo "⚠️  N'oubliez pas d'installer le certificat CA sur vos postes clients !"
echo ""