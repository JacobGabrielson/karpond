export CLUSTER_NAME=$USER-karpenter-demo
export AWS_DEFAULT_REGION=us-west-2
CLUSTER_ENDPOINT=$(aws eks describe-cluster --name ${CLUSTER_NAME} --query "cluster.endpoint" --output json)
export CLUSTER_ENDPOINT
