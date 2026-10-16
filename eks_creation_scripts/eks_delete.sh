#!/usr/bin/env bash
set -euo pipefail

# EKS cluster configuration
export AWS_PROFILE="captain"
export AWS_REGION="ap-south-1"
export CLUSTER_NAME="captain-eks"
export NODEGROUP_NAME="captain-workers"

# Check whether aws is installed and available.
require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: '$1' is required but was not found in PATH." >&2
    exit 1
  }
  echo "SUCCESS: '$1' is installed and available."
}
require_command aws
echo "aws is installed and available on the machine."

cat <<EOF
========================================
        EKS CLUSTER DELETION
========================================
AWS profile       : $AWS_PROFILE
AWS region        : $AWS_REGION
Cluster name      : $CLUSTER_NAME
Node group        : $NODEGROUP_NAME
========================================
EOF

echo "WARNING: This will permanently delete the node group and EKS cluster."
echo "IAM roles, subnets, VPCs, security groups, and other shared resources will not be deleted."
read -r -p "Type the cluster name '$CLUSTER_NAME' to continue: " CONFIRM_CLUSTER

if [[ "$CONFIRM_CLUSTER" != "$CLUSTER_NAME" ]]; then
  echo "Cluster name did not match. No resources were deleted." >&2
  exit 1
fi

echo "Checking AWS credentials..."
aws sts get-caller-identity --profile "$AWS_PROFILE" >/dev/null

if ! aws eks describe-cluster \
  --profile "$AWS_PROFILE" \
  --region "$AWS_REGION" \
  --name "$CLUSTER_NAME" >/dev/null 2>&1; then
  echo "EKS cluster '$CLUSTER_NAME' does not exist. Nothing to delete."
  exit 0
fi

if aws eks describe-nodegroup \
  --profile "$AWS_PROFILE" \
  --region "$AWS_REGION" \
  --cluster-name "$CLUSTER_NAME" \
  --nodegroup-name "$NODEGROUP_NAME" >/dev/null 2>&1; then
  echo "Deleting node group '$NODEGROUP_NAME'..."
  aws eks delete-nodegroup \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" \
    --cluster-name "$CLUSTER_NAME" \
    --nodegroup-name "$NODEGROUP_NAME"

  echo "Waiting for the node group to be deleted..."
  aws eks wait nodegroup-deleted \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" \
    --cluster-name "$CLUSTER_NAME" \
    --nodegroup-name "$NODEGROUP_NAME"
else
  echo "Node group '$NODEGROUP_NAME' does not exist. Continuing with cluster deletion."
fi

echo "Deleting EKS cluster '$CLUSTER_NAME'..."
aws eks delete-cluster \
  --profile "$AWS_PROFILE" \
  --region "$AWS_REGION" \
  --name "$CLUSTER_NAME"

echo "Waiting for the cluster to be deleted..."
aws eks wait cluster-deleted \
  --profile "$AWS_PROFILE" \
  --region "$AWS_REGION" \
  --name "$CLUSTER_NAME"

echo "EKS cluster '$CLUSTER_NAME' and node group '$NODEGROUP_NAME' were deleted successfully."
