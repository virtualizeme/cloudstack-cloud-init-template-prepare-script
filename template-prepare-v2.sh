#!/bin/bash
set -e

### Get Release
NAME=$(grep '^NAME=' /etc/os-release | cut -d '"' -f 2)
VERSION_ID=$(grep '^VERSION_ID=' /etc/os-release | cut -d '"' -f 2)

### FUNCTIONS
apt_update_upgrade() {
    apt update
    apt -y upgrade
}

set_locale() {
    locale-gen --purge en_US.UTF-8
    echo -e 'LANG="en_US.UTF-8"\nLANGUAGE="en_US:en"\n' > /etc/default/locale
    export LANGUAGE=en_US.UTF-8
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
}

apt_install_debian() {
    apt install -y acpid perl wget cloud-init cloud-initramfs-growroot
}

remove_user() {
    local username=$(awk -F: '$3 == 1000 { print $1 }' /etc/passwd) # znajduje uzytkownika o ID 1000
    deluser $username --remove-home
}

cloud_init_cleanup() {
    rm -rf /var/lib/cloud/*
    cloud-init clean
}

cloud_init_fix_services() {
    systemctl disable cloud-init.service cloud-init-local.service cloud-final.service cloud-config.service cloud-init-hotplugd.socket
    sed -i s/"WantedBy=cloud-init.target"/"WantedBy=multi-user.target"/g /lib/systemd/system/cloud-init-*.service /lib/systemd/system/cloud-init-hotplugd.socket
    systemctl enable cloud-init.service cloud-init-local.service cloud-final.service cloud-config.service cloud-init-hotplugd.socket
}

clear_files() {
    rm -f /etc/udev/rules.d/*
    rm -f /var/lib/dhcp/*
    rm -rf /etc/sudoers.d/*
}

clear_logs() {
    rm -rf /var/log/*
    logrotate -f /etc/logrotate.conf 2>/dev/null
}

clear_ssh() {
    rm -f /etc/ssh/*key*
}

clear_history() {
    rm -f /root/.bash_history
    history -c
    unset HISTFILE
}

halt_system() {
    halt -p
}

common_tasks() {
    apt_update_upgrade
    set_locale
    apt_install_debian
    remove_user
    cloud_init_config_cloudstack
    cloud_init_config_users
    cloud_init_config_ssh
    cloud_init_cleanup
    cloud_init_fix_services
    clear_files
    update_ssh_config
    clear_ssh
    clear_logs
    clear_history
    halt_system
}

### PREPARE OS FOR TEMPLATE

case "$NAME-$VERSION_ID" in
    "Debian GNU/Linux-12")
        common_tasks
        cloud_init_config_storage
        ;;
    "Ubuntu-22.04")
        common_tasks
        cloud_init_config_storage_ubuntu
        ;;
    "Kali GNU/Linux-2023.3")
        common_tasks
        cloud_init_config_storage_kali
        ;;
esac
