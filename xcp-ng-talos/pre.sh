#!/bin/bash

##########  New VM - XCP-ng  ##########
# https://www.talos.dev/v1.0/introduction/system-requirements/
#
# Template = 'Other Install Media'
# Name = 'talos-control-plane-1'
# Description = 'Talos Linux v1.0.0'
# vCPUs = '4'
# RAM = '4 GiB'
# Topology = '2 sockets, 1 core per socket'
# MAC = 'EA:41:7E:E8:12:1C'
# SR = 'Local SSD2'
# Name = 'talos-control-plane-1'
# Description = 'Talos SSD'
# Size = '10 GiB'
# ISO = 'https://talos-repository.s3.amazonaws.com/talos/v1.0.0/talos-v1.0.0-x86_64-disk1.iso'

##############################################################################
###                           DEFINING VARIABLES                           ###
##############################################################################
DEFAULT_CLUSTER_NAME="talos"
DEFAULT_CONTROL_PLANE_IP="192.168.65.41"

##############################################################################
###                              REQUIREMENTS                              ###
##############################################################################
APP_TALOSCTL="/usr/local/bin/talosctl"
if [ ! -f "$APP_TALOSCTL" ]; then
    read -p "Talosctl does not exist [$APP_TALOSCTL], do you want me to install it ? [Y/n] " response
    if [[ ! $response =~ ^([nN][oO]|[nN])$ ]]; then
        curl -Lo /usr/local/bin/talosctl https://github.com/siderolabs/talos/releases/download/v1.0.0/talosctl-$(uname -s | tr "[:upper:]" "[:lower:]")-amd64
        chmod +x /usr/local/bin/talosctl
        talosctl version
    else
        echo "You chose not to install Talosctl. We exit."
        exit 1
    fi
fi