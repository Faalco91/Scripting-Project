#!/bin/bash
source "$(dirname "$0")/modules/install.sh"

install_prerequisites
create_databases
install_dolibarr
install_glpi