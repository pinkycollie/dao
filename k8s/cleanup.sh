#!/bin/bash
# Cleanup script to remove all DAO Platform resources

set -e

echo "====================================="
echo "DAO Platform Kubernetes Cleanup"
echo "====================================="
echo ""

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${RED}WARNING: This will delete all DAO Platform resources!${NC}"
read -p "Are you sure you want to continue? (yes/no) " -r
echo
if [[ ! $REPLY == "yes" ]]; then
    echo "Cleanup cancelled"
    exit 0
fi

echo -e "${YELLOW}Deleting resources...${NC}"

# Delete tenant configurations
kubectl delete -f k8s/tenants/ --ignore-not-found=true

# Delete monitoring
kubectl delete -f k8s/monitoring/ --ignore-not-found=true

# Delete HPA
kubectl delete -f k8s/base/hpa.yaml --ignore-not-found=true

# Delete application resources
kubectl delete -f k8s/base/ingress.yaml --ignore-not-found=true
kubectl delete -f k8s/base/service.yaml --ignore-not-found=true
kubectl delete -f k8s/base/deployment.yaml --ignore-not-found=true

# Delete secrets and configmaps
kubectl delete -f k8s/base/secrets.yaml --ignore-not-found=true
kubectl delete -f k8s/base/configmap.yaml --ignore-not-found=true

# Delete PVCs (this will delete stored data!)
echo -e "${RED}Deleting persistent volumes (data will be lost)...${NC}"
kubectl delete pvc -n dao-platform --all

# Delete namespace (this will delete everything in the namespace)
echo -e "${YELLOW}Deleting namespace...${NC}"
kubectl delete namespace dao-platform --ignore-not-found=true

echo -e "${GREEN}Cleanup complete!${NC}"
