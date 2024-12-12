#!/bin/bash

# Function to delete pods stuck in "Terminating" state
delete_stuck_pods() {
  echo "Finding and deleting pods stuck in Terminating state..."
  kubectl get pods --all-namespaces | grep Terminating | awk '{print $1, $2}' | while read namespace pod; do
    echo "Deleting pod: $pod in namespace: $namespace"
    kubectl delete pod $pod -n $namespace --force --grace-period=0
  done
}

# Function to remove nodes that are no longer available
clean_up_unavailable_nodes() {
  echo "Finding and removing unavailable nodes..."
  kubectl get nodes | grep NotReady | awk '{print $1}' | while read node; do
    echo "Removing node: $node"
    kubectl delete node $node
  done
}

# Main script execution
echo "Starting cleanup process..."
delete_stuck_pods
clean_up_unavailable_nodes
echo "Cleanup process complete."