#!/bin/bash

export PROJECT_DIR=$(git rev-parse --show-toplevel)

source "${PROJECT_DIR}/xcp-ng-talos/pre.sh"

CLUSTER_NAME=${CLUSTER_NAME:=${DEFAULT_CLUSTER_NAME}}
CONTROL_PLANE_IP=${CONTROL_PLANE_IP:=${DEFAULT_CONTROL_PLANE_IP}}

echo "PROJECT_DIR=${PROJECT_DIR}"
echo "CLUSTER_NAME=$CLUSTER_NAME"
echo "CONTROL_PLANE_IP=$CONTROL_PLANE_IP"

# Getting Started - Talos Linux v1.0.0
# https://www.talos.dev/v1.0/introduction/getting-started/

create () {
    # Remove old cluster configs
    rm -f   "${PROJECT_DIR}/xcp-ng-talos/controlplane.yaml" \
            "${PROJECT_DIR}/xcp-ng-talos/talosconfig" \
            "${PROJECT_DIR}/xcp-ng-talos/worker.yaml"

    # Generate cluster configs
    echo "Generate cluster configs"
    echo ""
    talosctl gen config $CLUSTER_NAME https://$CONTROL_PLANE_IP:6443 \
        --install-disk "/dev/xvda"

    # Apply Configuration
    talosctl apply-config --insecure \
        --nodes $CONTROL_PLANE_IP \
        --file "${PROJECT_DIR}/xcp-ng-talos/controlplane.yaml"

    # Endpoints configuration
    talosctl --talosconfig="${PROJECT_DIR}/xcp-ng-talos/talosconfig" \
        config endpoint $CONTROL_PLANE_IP
    
    # Nodes configuration
    talosctl --talosconfig="${PROJECT_DIR}/xcp-ng-talos/talosconfig" \
        config node $CONTROL_PLANE_IP

    echo "Appling configuration, wait for server info to appear..."
    echo ""
    watch talosctl --talosconfig="${PROJECT_DIR}/xcp-ng-talos/talosconfig" \
        --nodes $CONTROL_PLANE_IP version
    
    # Add context if we don't have it from previous run
    if [[ $(talosctl config contexts) == *$CONTROL_PLANE_IP* ]]; then
        echo "Please copy secrets from ./talosconfig to '~/.talos/config'"
        echo ""
    else
        talosctl config merge ${PROJECT_DIR}/xcp-ng-talos/talosconfig
    fi

    # Untaint Control Plane
    # https://www.sidero.dev/v0.3/guides/bootstrapping/#untaint-control-plane
    kubectl taint node talos-192-168-65-41 node-role.kubernetes.io/master:NoSchedule-
}

bootstrap() {
    # IMPORTANT: the bootstrap operation should only be called ONCE and only on a SINGLE controlplane node!
    talosctl --talosconfig="${PROJECT_DIR}/xcp-ng-talos/talosconfig" \
        bootstrap --nodes $CONTROL_PLANE_IP

    # Download Kubernetes client configuration
    talosctl --talosconfig="${PROJECT_DIR}/xcp-ng-talos/talosconfig" \
        kubeconfig

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
echo "./xcp-talos.sh [step 1] create        - Create Kubernetes Cluster"
echo "./xcp-talos.sh [step 2] bootstrap     - IMPORTANT: the bootstrap operation should only be called ONCE and only on a SINGLE controlplane node!"
echo "./xcp-talos.sh reboot                 - Reboot node"
echo "./xcp-talos.sh shutdown               - Shut down node"
echo "#################################################################################"
echo ""

"$@"