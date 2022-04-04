#!/bin/bash

source ${BASH_SOURCE%/*}/pre.sh

CLUSTER_NAME=${CLUSTER_NAME:=${DEFAULT_CLUSTER_NAME}}
CONTROL_PLANE_IP=${CONTROL_PLANE_IP:=${DEFAULT_CONTROL_PLANE_IP}}

# Getting Started - Talos Linux v1.0.0
# https://www.talos.dev/v1.0/introduction/getting-started/

create () {
    # Remove old cluster configs
    rm -f ./controlplane.yaml ./talosconfig ./worker.yaml

    # Generate cluster configs
    echo "Generate cluster configs"
    echo ""
    talosctl gen config $CLUSTER_NAME https://$CONTROL_PLANE_IP:6443 \
        --install-disk "/dev/xvda"

    # Apply Configuration
    talosctl apply-config --insecure \
        --nodes $CONTROL_PLANE_IP \
        --file ./controlplane.yaml

    # Endpoints configuration
    talosctl --talosconfig=./talosconfig \
        config endpoint $CONTROL_PLANE_IP
    
    # Nodes configuration
    talosctl --talosconfig=./talosconfig \
        config node $CONTROL_PLANE_IP

    echo "Appling configuration, wait for server info to appear..."
    echo ""
    watch talosctl --talosconfig=./talosconfig \
        --nodes $CONTROL_PLANE_IP version
    
    # Add context if we don't have it from previous run
    if [[ $(talosctl config contexts) == *$CONTROL_PLANE_IP* ]]; then
        echo "Please adjust secrets from '/Users/dan.serban/.talos/config'"
        echo ""
    else
        talosctl config merge ./talosconfig
    fi
}

bootstrap() {
    # IMPORTANT: the bootstrap operation should only be called ONCE and only on a SINGLE controlplane node!
    talosctl bootstrap --nodes $CONTROL_PLANE_IP

    # Download Kubernetes client configuration
    talosctl kubeconfig

    echo "Cluster starts configuring, wait for nodes to appear..."
    echo ""
    watch kubectl get nodes
}

reboot() {
    echo "Reboot node..."
    echo ""
    talosctl -n $CONTROL_PLANE_IP reboot
}

shutdown() {
    echo "Shut down node..."
    echo ""
    talosctl -n $CONTROL_PLANE_IP shutdown
}


##############################################################################
###                             DISPLAY OPTIONS                            ###
##############################################################################
echo ""
echo "### OPTIONS #####################################################################"
echo "./xcp-talos.sh create           - Create Kubernetes Cluster"
echo "./xcp-talos.sh bootstrap        - IMPORTANT: the bootstrap operation should only be called ONCE and only on a SINGLE controlplane node!"
echo "./xcp-talos.sh reboot           - Reboot node"
echo "./xcp-talos.sh shutdown         - Shut down node"
echo "#################################################################################"
echo ""

"$@"