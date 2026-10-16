EKS Cluster Management Scripts:
These scripts create and delete an Amazon EKS cluster in AWS using the AWS CLI.

Scripts:
```
Script	            Purpose
create_eks.sh	      Creates the EKS cluster and managed node group, then updates the local kubeconfig.
eks_delete.sh	      Deletes the managed node group first and then deletes the EKS cluster.
```

Configuration:
The scripts currently use the following configuration:
```
AWS profile       : captain
AWS region        : ap-south-1
Cluster name      : captain-eks
Kubernetes version: 1.36
Node group        : captain-workers
Worker nodes      : 2 x t3.medium
Subnets           : subnet-0d4fc000c9b699db6, subnet-03ecc3b339f36ff72

The creation script also uses these IAM roles:
Cluster role: arn:aws:iam::11111111111:role/AmazonEKSAutoClusterRole
Node role   : arn:aws:iam::11111111111:role/AmazonEKSAutoNodeRole
Update the values in the scripts before running them in another AWS account, region, or VPC.
```
Prerequisites
Install and configure the following tools:
- AWS CLI
- kubectl
- Docker, required by create_eks.sh
- An AWS CLI profile named captain
- IAM permissions to create and delete EKS clusters and managed node groups
- The configured IAM roles and subnets must already exist
```
Verify the AWS profile before making changes:
aws sts get-caller-identity --profile captain
Make the scripts executable
chmod +x create_eks.sh eks_delete.sh
Create the EKS cluster
Run:
./create_eks.sh
The script will:
1. Check that the required commands are installed.
2. Display the planned cluster configuration.
3. Ask for confirmation.
4. Validate the AWS credentials.
5. Confirm that the cluster does not already exist.
6. Create the EKS control plane.
7. Wait for the cluster to become active.
8. Create the managed node group with two t3.medium instances.
9. Wait for the node group to become active.
10. Update the local kubeconfig.
11. Display the worker nodes using kubectl get nodes.
Delete the EKS cluster
Run:
./eks_delete.sh
The deletion script requires you to type the exact cluster name:
captain-eks
It will then:
1. Validate the AWS credentials.
2. Check whether the cluster exists.
3. Delete the managed node group, if it exists.
4. Wait for the node group deletion to complete.
5. Delete the EKS cluster.
6. Wait for the cluster deletion to complete.
Resources not deleted
eks_delete.sh does not delete the following resources:
- IAM roles
- VPCs
- Subnets
- Security groups
- Route tables
- NAT gateways
- Other AWS resources outside the EKS cluster and managed node group
These resources may continue to incur AWS charges, especially NAT gateways and other networking resources.
Important notes
- Cluster deletion is permanent and removes the EKS control plane.
- Deleting the managed node group removes the worker nodes and workloads running on them.
- Back up any required Kubernetes manifests, persistent data, or application configuration before deletion.
- The scripts use AWS CLI wait commands and may take several minutes to complete.
- Kubernetes version 1.36 must be supported by the target AWS region and account when the creation script is run.

```
```
Troubleshooting:
AWS credentials error
Confirm that the captain profile exists and is authenticated:
aws configure list --profile captain
aws sts get-caller-identity --profile captain
Cluster or node group already exists
The creation script stops if captain-eks already exists. Either use the existing cluster or update CLUSTER_NAME and NODEGROUP_NAME in the script.
Access denied
Ensure the AWS identity has permissions for the EKS, IAM, EC2, and related operations required by the scripts.
Node group fails to create
Check that:
- The node IAM role has the required EKS worker policies.
```
- The selected subnets are valid for the cluster and have suitable networking.
- The account has capacity for two t3.medium instances in the selected Availability Zones.
- The selected AMI type and Kubernetes version are supported.
