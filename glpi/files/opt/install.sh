#!/bin/bash
set -e -u -o pipefail

Install_GLPI() {
    su www-data -s /bin/bash -c 'bin/console database:install \
        --db-host="$GLPI_DB_HOST" \
        --db-port="$GLPI_DB_PORT" \
        --db-name="$GLPI_DB_NAME" \
        --db-user="$GLPI_DB_USER" \
        --db-password="$GLPI_DB_PASSWORD" \
        --no-interaction --quiet'
}

greetings() {
    local new_installation="$1"

    echo $'\n\n================================================================'
    echo $'Welcome to\n'
    echo $' ██████╗ ██╗     ██████╗ ██╗'
    echo $'██╔════╝ ██║     ██╔══██╗██║'
    echo $'██║  ███╗██║     ██████╔╝██║'
    echo $'██║   ██║██║     ██╔═══╝ ██║'
    echo $'╚██████╔╝███████╗██║     ██║'
    echo $' ╚═════╝ ╚══════╝╚═╝     ╚═╝\n'

    echo $'https://glpi-project.org'

    if [ "$new_installation" = true ]; then
        echo $'\n================================================================'
        echo $'GLPI installation completed successfully!\n'
        echo $'Please access GLPI via your web browser to complete the setup.'
        echo $'You can use the following credentials:\n'
        echo $'- Username: glpi'
        echo $'- Password: glpi'
        echo $'================================================================\n'
    fi
}

Update_GLPI() {
    su www-data -s /bin/bash -c 'bin/console database:update --no-interaction --quiet'
}

GLPI_Installed() {
    if [ -f "${GLPI_CONFIG_DIR}/config_db.php" ]; then
        # check if the glpi_logs table exists (-N to skip column names, -s for non tabular output)
        if [ $(mysql -N -s -h "$GLPI_DB_HOST" -u "$GLPI_DB_USER" -p"$GLPI_DB_PASSWORD" -e "select count(*) from information_schema.tables where \
        table_schema='$GLPI_DB_NAME' and table_name='glpi_logs';") -eq 1 ]
        then
            return 0
        fi
    fi

    # If the config_db.php file does not exist or the glpi_logs table is not found,
    # GLPI is not installed
    return 1
}

if ! GLPI_Installed; then
    if [[ -z "$GLPI_SKIP_AUTOINSTALL" ]]; then
        echo "GLPI is not installed. but auto-install is enabled. Starting installation."
        echo "Please wait until you see the greeting, this may take a minute..."
        Install_GLPI
        greetings true
    fi
else
    if [[ -z "$GLPI_SKIP_AUTOUPDATE" ]]; then
        echo "GLPI is not installed, but auto-update is enabled. Starting update..."
        Update_GLPI
        greetings false
    fi
fi
