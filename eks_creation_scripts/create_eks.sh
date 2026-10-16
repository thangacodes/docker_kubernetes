#!/usr/bin/env bash
set -euo pipefail

# EKS cluster configuration
export AWS_PROFILE="captain"
export AWS_REGION="ap-south-1"
export CLUSTER_NAME="captain-eks"
export CLUSTER_ROLE_ARN="arn:aws:iam::11111111111:role/AmazonEKSAutoClusterRole"
export NODE_ROLE_ARN="arn:aws:iam::11111111111:role/AmazonEKSAutoNodeRole"
export SUBNET_1="subnet-0d4fc000c9b699db6"
export SUBNET_2="subnet-03ecc3b339f36ff72"
export NODEGROUP_NAME="captain-workers"

# Check whether aws, kubectl, and docker are installed and available.
require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: '$1' is required but was not found in PATH." >&2
    exit 1
  }
  echo "SUCCESS: '$1' is installed and available."
}

require_command aws
require_command kubectl
require_command docker

echo "aws, kubectl, and docker are installed and available on the machine."

cat <<EOF
========================================
        EKS CLUSTER BLUEPRINT
========================================
AWS profile       : $AWS_PROFILE
AWS region        : $AWS_REGION
Cluster name      : $CLUSTER_NAME
Kubernetes version: 1.36
Subnets           : $SUBNET_1, $SUBNET_2
Node group        : $NODEGROUP_NAME
Worker nodes      : 2 x t3.medium
AMI               : AL2023_x86_64_STANDARD
========================================
EOF

read -r -p "Do you want to create this EKS cluster? (yes/no): " CREATE_CLUSTER
case "${CREATE_CLUSTER,,}" in
  yes|y)
    echo "Proceeding with EKS cluster creation..."
    ;;
  no|n)
    echo "Cluster creation cancelled."
    exit 0
    ;;
  *)
    echo "Please answer yes or no. No resources were created." >&2
    exit 1
    ;;
esac

echo "Checking AWS credentials..."
aws sts get-caller-identity --profile "$AWS_PROFILE" >/dev/null

if aws eks describe-cluster \
  --profile "$AWS_PROFILE" \
  --region "$AWS_REGION" \
  --name "$CLUSTER_NAME" >/dev/null 2>&1; then
  echo "ERROR: EKS cluster '$CLUSTER_NAME' already exists."
  exit 1
fi

echo "Creating EKS cluster '$CLUSTER_NAME'..."
aws eks create-cluster \
  --profile "$AWS_PROFILE" \
  --region "$AWS_REGION" \
  --name "$CLUSTER_NAME" \
  --kubernetes-version 1.36 \
  --role-arn "$CLUSTER_ROLE_ARN" \
  --resources-vpc-config "subnetIds=$SUBNET_1,$SUBNET_2"

echo "Waiting for the cluster to become active..."
aws eks wait cluster-active \
  --profile "$AWS_PROFILE" \
  --region "$AWS_REGION" \
  --name "$CLUSTER_NAME"

echo "Creating node group '$NODEGROUP_NAME'..."
aws eks create-nodegroup \
  --profile "$AWS_PROFILE" \
  --region "$AWS_REGION" \
  --cluster-name "$CLUSTER_NAME" \
  --nodegroup-name "$NODEGROUP_NAME" \
  --node-role "$NODE_ROLE_ARN" \
  --subnets "$SUBNET_1" "$SUBNET_2" \
  --scaling-config minSize=2,maxSize=2,desiredSize=2 \
  --instance-types t3.medium \
  --ami-type AL2023_x86_64_STANDARD

echo "Waiting for the node group to become active..."
aws eks wait nodegroup-active \
  --profile "$AWS_PROFILE" \
  --region "$AWS_REGION" \
  --cluster-name "$CLUSTER_NAME" \
  --nodegroup-name "$NODEGROUP_NAME"

echo "Updating kubeconfig..."
aws eks update-kubeconfig \
  --profile "$AWS_PROFILE" \
  --region "$AWS_REGION" \
  --name "$CLUSTER_NAME"

echo "Cluster setup complete. Nodes are below:"
kubectl get nodes
