#!/bin/bash
# Deploy all Kubernetes resources for the DAO Platform

set -e

echo "====================================="
echo "DAO Platform Kubernetes Deployment"
echo "====================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    exit 1
fi

# Check if connected to a cluster
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Not connected to a Kubernetes cluster${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 1: Creating namespace...${NC}"
kubectl apply -f k8s/base/namespace.yaml
echo -e "${GREEN}✓ Namespace created${NC}"
echo ""

echo -e "${YELLOW}Step 2: Deploying ConfigMaps...${NC}"
kubectl apply -f k8s/base/configmap.yaml
echo -e "${GREEN}✓ ConfigMaps deployed${NC}"
echo ""

echo -e "${YELLOW}Step 3: Deploying Secrets...${NC}"
echo -e "${YELLOW}WARNING: Make sure you've updated secrets with actual values!${NC}"
read -p "Have you updated the secrets? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Please update k8s/base/secrets.yaml with actual values before deploying${NC}"
    exit 1
fi
kubectl apply -f k8s/base/secrets.yaml
echo -e "${GREEN}✓ Secrets deployed${NC}"
echo ""

echo -e "${YELLOW}Step 4: Deploying application...${NC}"
kubectl apply -f k8s/base/deployment.yaml
kubectl apply -f k8s/base/service.yaml
kubectl apply -f k8s/base/ingress.yaml
echo -e "${GREEN}✓ Application deployed${NC}"
echo ""

echo -e "${YELLOW}Step 5: Deploying HPA...${NC}"
kubectl apply -f k8s/base/hpa.yaml
echo -e "${GREEN}✓ HPA deployed${NC}"
echo ""

echo -e "${YELLOW}Step 6: Deploying monitoring (Prometheus & Grafana)...${NC}"
kubectl apply -f k8s/monitoring/prometheus-config.yaml
kubectl apply -f k8s/monitoring/prometheus-deployment.yaml
kubectl apply -f k8s/monitoring/grafana-deployment.yaml
echo -e "${GREEN}✓ Monitoring deployed${NC}"
echo ""

echo -e "${YELLOW}Step 7: Deploying tenant configurations...${NC}"
kubectl apply -f k8s/tenants/vr4deaf-configmap.yaml
echo -e "${GREEN}✓ Tenant configurations deployed${NC}"
echo ""

echo -e "${YELLOW}Waiting for deployments to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/dao-platform -n dao-platform
kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n dao-platform
kubectl wait --for=condition=available --timeout=300s deployment/grafana -n dao-platform
echo -e "${GREEN}✓ All deployments are ready${NC}"
echo ""

echo "====================================="
echo -e "${GREEN}Deployment Complete!${NC}"
echo "====================================="
echo ""
echo "Next steps:"
echo "1. Configure DNS to point to the ingress IP:"
echo "   kubectl get svc -n ingress-nginx"
echo ""
echo "2. Access Prometheus:"
echo "   kubectl port-forward -n dao-platform svc/prometheus 9090:9090"
echo "   Open http://localhost:9090"
echo ""
echo "3. Access Grafana:"
echo "   kubectl port-forward -n dao-platform svc/grafana 3000:3000"
echo "   Open http://localhost:3000 (admin/admin123)"
echo ""
echo "4. Check pod status:"
echo "   kubectl get pods -n dao-platform"
echo ""
echo "5. View logs:"
echo "   kubectl logs -f -n dao-platform -l app=dao-platform"
echo ""
echo "For more information, see k8s/README.md"
