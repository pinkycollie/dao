# Kubernetes Deployment Guide for DAO Platform

## Overview

This guide provides comprehensive instructions for deploying the DAO Platform on Kubernetes with integrated Prometheus/Grafana monitoring and Horizontal Pod Autoscaling (HPA). The platform supports multi-tenant architectures with isolated configurations for each tenant.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [Quick Start](#quick-start)
4. [Deployment Steps](#deployment-steps)
5. [Monitoring Setup](#monitoring-setup)
6. [Scaling Configuration](#scaling-configuration)
7. [Multi-Tenant Management](#multi-tenant-management)
8. [Accessibility Features](#accessibility-features)
9. [Troubleshooting](#troubleshooting)
10. [Production Considerations](#production-considerations)

## Prerequisites

### Required Tools
- Kubernetes cluster (v1.24+)
- `kubectl` CLI tool configured
- Docker for building images
- `helm` (optional, for package management)

### Required Kubernetes Resources
- **metrics-server**: Required for HPA CPU/memory metrics
- **nginx-ingress-controller**: For routing traffic
- **cert-manager** (optional): For automatic TLS certificate management
- **Storage provisioner**: For persistent volumes (Prometheus and Grafana)

### Install metrics-server
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### Install nginx-ingress-controller
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
```

## Architecture Overview

### Components

```
┌─────────────────────────────────────────────────────────┐
│                    Ingress (nginx)                       │
│              (Multi-tenant domain routing)               │
└─────────────────────┬───────────────────────────────────┘
                      │
        ┌─────────────┴─────────────┐
        │                           │
┌───────▼──────┐          ┌─────────▼────────┐
│ DAO Platform │          │   Monitoring     │
│   Service    │◄─────────┤   (Prometheus)   │
│              │  Scrape  │                  │
│  (Load Bal.) │          └──────────────────┘
└───────┬──────┘                   │
        │                          │
   ┌────▼─────┐              ┌─────▼────┐
   │   Pods   │              │ Grafana  │
   │ (3-10)   │              │Dashboard │
   │  + HPA   │              └──────────┘
   └──────────┘
        │
   ┌────▼─────┐
   │PostgreSQL│
   │ Database │
   └──────────┘
```

### Key Features
- **Multi-tenant support**: Domain/subdomain-based tenant isolation
- **Auto-scaling**: HPA based on CPU/memory utilization
- **Monitoring**: Prometheus metrics + Grafana dashboards
- **High availability**: 3-10 pod replicas with health checks
- **Security**: RBAC, secrets management, non-root containers

## Quick Start

### 1. Build and Push Docker Image

```bash
# Build the Docker image
docker build -t your-registry/dao-platform:latest .

# Push to your container registry
docker push your-registry/dao-platform:latest
```

### 2. Update Image Reference

Edit `k8s/base/deployment.yaml` and update the image reference:
```yaml
containers:
- name: dao-platform
  image: your-registry/dao-platform:latest
```

### 3. Configure Secrets

**Important**: Update secrets before deploying!

```bash
# Create secrets from file or literal values
kubectl create secret generic dao-platform-secrets \
  --namespace=dao-platform \
  --from-literal=NEXTAUTH_SECRET=$(openssl rand -base64 32) \
  --from-literal=POSTGRES_URL='your-database-url' \
  --from-literal=AUTH_GITHUB_ID='your-github-id' \
  --from-literal=AUTH_GITHUB_SECRET='your-github-secret'
```

Or edit `k8s/base/secrets.yaml` with actual values (ensure it's not committed to git!).

### 4. Deploy Everything

```bash
# Create namespace
kubectl apply -f k8s/base/namespace.yaml

# Deploy application
kubectl apply -f k8s/base/configmap.yaml
kubectl apply -f k8s/base/secrets.yaml
kubectl apply -f k8s/base/deployment.yaml
kubectl apply -f k8s/base/service.yaml
kubectl apply -f k8s/base/ingress.yaml
kubectl apply -f k8s/base/hpa.yaml

# Deploy monitoring
kubectl apply -f k8s/monitoring/prometheus-config.yaml
kubectl apply -f k8s/monitoring/prometheus-deployment.yaml
kubectl apply -f k8s/monitoring/grafana-deployment.yaml

# Deploy tenant configurations
kubectl apply -f k8s/tenants/vr4deaf-configmap.yaml
```

### 5. Verify Deployment

```bash
# Check pod status
kubectl get pods -n dao-platform

# Check HPA status
kubectl get hpa -n dao-platform

# Check services
kubectl get svc -n dao-platform

# View logs
kubectl logs -f -n dao-platform -l app=dao-platform
```

## Deployment Steps

### Step 1: Namespace Creation

```bash
kubectl apply -f k8s/base/namespace.yaml
```

Verify:
```bash
kubectl get namespace dao-platform
```

### Step 2: Configuration Management

#### ConfigMap
The ConfigMap contains non-sensitive application configuration:
- Environment variables
- Feature flags
- Logging configuration

```bash
kubectl apply -f k8s/base/configmap.yaml
kubectl describe configmap dao-platform-config -n dao-platform
```

#### Secrets
**Security Note**: Never commit actual secrets to git. Use one of:
1. Kubernetes secrets from literals (shown above)
2. External secret managers (AWS Secrets Manager, HashiCorp Vault)
3. Sealed Secrets for GitOps

```bash
# Example: Create from file
kubectl create secret generic dao-platform-secrets \
  --from-env-file=.env.production \
  --namespace=dao-platform
```

### Step 3: Application Deployment

```bash
kubectl apply -f k8s/base/deployment.yaml
```

Monitor rollout:
```bash
kubectl rollout status deployment/dao-platform -n dao-platform
```

### Step 4: Service and Ingress

```bash
kubectl apply -f k8s/base/service.yaml
kubectl apply -f k8s/base/ingress.yaml
```

Get ingress details:
```bash
kubectl get ingress -n dao-platform
kubectl describe ingress dao-platform-ingress -n dao-platform
```

### Step 5: Configure DNS

Point your domains to the ingress controller's external IP:
```bash
kubectl get svc -n ingress-nginx
```

Add DNS records:
```
dao-platform.local     A    <EXTERNAL-IP>
*.dao-platform.local   A    <EXTERNAL-IP>
vr4deaf.org           A    <EXTERNAL-IP>
*.vr4deaf.org         A    <EXTERNAL-IP>
```

## Monitoring Setup

### Prometheus

Prometheus scrapes metrics from:
- Application `/api/metrics` endpoint
- Kubernetes API server
- Node metrics
- Pod metrics

```bash
# Deploy Prometheus
kubectl apply -f k8s/monitoring/prometheus-config.yaml
kubectl apply -f k8s/monitoring/prometheus-deployment.yaml

# Access Prometheus UI (port-forward for testing)
kubectl port-forward -n dao-platform svc/prometheus 9090:9090
# Open http://localhost:9090
```

### Grafana

```bash
# Deploy Grafana
kubectl apply -f k8s/monitoring/grafana-deployment.yaml

# Get admin password (default: admin123)
kubectl get secret grafana-admin -n dao-platform -o jsonpath="{.data.password}" | base64 --decode

# Access Grafana UI
kubectl port-forward -n dao-platform svc/grafana 3000:3000
# Open http://localhost:3000
```

### Import Dashboards

1. Log into Grafana (admin/admin123)
2. Navigate to **Dashboards** → **Import**
3. Upload JSON files from `k8s/dashboards/`:
   - `dao-platform-overview.json`
   - `dao-tenant-metrics.json`

### Available Metrics

The `/api/metrics` endpoint exposes:
- `dao_platform_info`: Platform version information
- `dao_http_requests_total`: HTTP request counters
- `dao_active_tenants`: Number of active tenants
- `nodejs_memory_usage_bytes`: Memory usage metrics
- `nodejs_process_cpu_usage_percentage`: CPU usage
- `dao_uptime_seconds`: Application uptime

## Scaling Configuration

### Horizontal Pod Autoscaler (HPA)

```bash
kubectl apply -f k8s/base/hpa.yaml
```

The HPA configuration:
- **Min replicas**: 3 (high availability)
- **Max replicas**: 10 (prevent resource exhaustion)
- **CPU target**: 70% utilization
- **Memory target**: 80% utilization

View HPA status:
```bash
kubectl get hpa -n dao-platform
kubectl describe hpa dao-platform-hpa -n dao-platform
```

### Manual Scaling

```bash
# Scale manually (overrides HPA temporarily)
kubectl scale deployment dao-platform --replicas=5 -n dao-platform

# Restore HPA control
kubectl autoscale deployment dao-platform --min=3 --max=10 --cpu-percent=70 -n dao-platform
```

### Load Testing

Test autoscaling with load:
```bash
# Install hey (HTTP load generator)
# https://github.com/rakyll/hey

# Generate load
hey -z 5m -c 50 -q 10 http://dao-platform.local

# Watch HPA response
kubectl get hpa -n dao-platform --watch
```

## Multi-Tenant Management

### Tenant Architecture

Each tenant can have:
1. **Isolated configuration** (ConfigMap)
2. **Isolated secrets** (Secret)
3. **Shared infrastructure** (Deployment, Service)
4. **Domain-based routing** (Ingress)

### Adding a New Tenant

#### 1. Create Tenant Configuration

Copy the template:
```bash
cp k8s/tenants/tenant-template.yaml k8s/tenants/new-tenant-configmap.yaml
```

Edit and customize:
```yaml
metadata:
  name: tenant-newtenant-config
  labels:
    tenant: newtenant
data:
  TENANT_ID: "newtenant"
  TENANT_NAME: "New Tenant Name"
  TENANT_DOMAIN: "newtenant.com"
  # ... customize features
```

#### 2. Create Tenant Secrets

```bash
kubectl create secret generic tenant-newtenant-secrets \
  --namespace=dao-platform \
  --from-literal=TENANT_DB_URL='postgresql://...' \
  --from-literal=TENANT_API_KEY='...'
```

#### 3. Update Ingress

Add tenant domain to `k8s/base/ingress.yaml`:
```yaml
rules:
- host: newtenant.com
  http:
    paths:
    - path: /
      pathType: Prefix
      backend:
        service:
          name: dao-platform
          port:
            number: 80
```

Apply changes:
```bash
kubectl apply -f k8s/base/ingress.yaml
kubectl apply -f k8s/tenants/new-tenant-configmap.yaml
```

#### 4. Configure DNS

Add DNS records for the new tenant domain pointing to the ingress IP.

### Tenant Isolation Levels

**Current Implementation**: Shared infrastructure with configuration isolation
- All tenants share the same pods
- Tenant identification via domain/subdomain
- Configuration via environment-specific ConfigMaps

**Future Enhancements**:
- Namespace-per-tenant for stronger isolation
- Dedicated database per tenant
- Resource quotas per tenant
- Network policies for tenant isolation

### Example: VR4Deaf Tenant

The repository includes a complete example for vr4deaf.org:

```bash
kubectl apply -f k8s/tenants/vr4deaf-configmap.yaml
```

This tenant includes:
- Accessibility features (captions, sign language, screen reader)
- Vocational rehabilitation tools
- High-contrast UI theme
- ADA compliance (WCAG AAA level)

## Accessibility Features

### Built-in Accessibility Support

The platform includes extensive accessibility features, especially for the vocational rehabilitation use case (vr4deaf.org):

#### Visual Accessibility
- **High contrast mode**: Enhanced visibility
- **Large font options**: Configurable font sizes
- **Screen reader support**: ARIA labels, semantic HTML
- **Keyboard navigation**: Full keyboard accessibility

#### Audio/Video Accessibility
- **Real-time captions**: Automated captioning support
- **Sign language interpretation**: Video relay services
- **Video notifications**: Visual alerts for deaf users
- **Text-to-speech**: Optional TTS for content

#### Navigation Accessibility
- **Skip links**: Quick navigation to main content
- **Focus indicators**: Clear focus states
- **Consistent layout**: Predictable navigation
- **Error handling**: Clear, accessible error messages

### Compliance Standards

Configured compliance levels:
- **WCAG 2.1 Level AAA**: Highest accessibility standard
- **ADA Compliance**: Americans with Disabilities Act
- **Section 508**: Federal accessibility requirements

### Tenant-Specific Accessibility

Enable accessibility features per tenant in ConfigMap:
```yaml
ENABLE_CAPTIONS: "true"
ENABLE_SIGN_LANGUAGE: "true"
ENABLE_ACCESSIBILITY_TOOLS: "true"
SCREEN_READER_SUPPORT: "true"
WCAG_LEVEL: "AAA"
```

### Video Support Integration

For tenants requiring video support:
1. Configure video provider: Zoom, Teams, etc.
2. Enable caption provider
3. Set up interpreter booking system
4. Configure video relay services

## Troubleshooting

### Common Issues

#### 1. Pods not starting

```bash
# Check pod status
kubectl get pods -n dao-platform

# View pod logs
kubectl logs -n dao-platform <pod-name>

# Describe pod for events
kubectl describe pod -n dao-platform <pod-name>
```

Common causes:
- Missing secrets
- Image pull errors
- Resource constraints
- Health check failures

#### 2. HPA not scaling

```bash
# Check metrics-server
kubectl get apiservice v1beta1.metrics.k8s.io -o yaml

# Check HPA status
kubectl describe hpa dao-platform-hpa -n dao-platform

# View current metrics
kubectl top pods -n dao-platform
```

#### 3. Ingress not routing

```bash
# Check ingress status
kubectl describe ingress dao-platform-ingress -n dao-platform

# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

#### 4. Metrics not appearing in Prometheus

```bash
# Test metrics endpoint
kubectl port-forward -n dao-platform svc/dao-platform 8080:80
curl http://localhost:8080/api/metrics

# Check Prometheus targets
# Port-forward Prometheus and visit http://localhost:9090/targets
```

### Debug Commands

```bash
# Interactive shell in pod
kubectl exec -it -n dao-platform <pod-name> -- /bin/sh

# View all resources
kubectl get all -n dao-platform

# View events
kubectl get events -n dao-platform --sort-by='.lastTimestamp'

# Resource usage
kubectl top pods -n dao-platform
kubectl top nodes
```

## Production Considerations

### Security Hardening

1. **Secrets Management**
   - Use external secret managers (Vault, AWS Secrets Manager)
   - Rotate secrets regularly
   - Never commit secrets to git

2. **Network Policies**
   - Implement network policies for pod communication
   - Restrict egress traffic
   - Use service mesh for mTLS (optional)

3. **RBAC**
   - Principle of least privilege
   - Service account per component
   - Regular access audits

4. **Image Security**
   - Scan images for vulnerabilities
   - Use minimal base images
   - Sign images with Cosign

### High Availability

1. **Multi-zone deployment**
   - Deploy across multiple availability zones
   - Use pod anti-affinity rules

2. **Database HA**
   - Use managed PostgreSQL (RDS, Cloud SQL)
   - Configure read replicas
   - Implement automatic failover

3. **Backup Strategy**
   - Regular database backups
   - Backup Persistent Volumes
   - Test restore procedures

### Performance Optimization

1. **Resource Limits**
   - Set appropriate CPU/memory limits
   - Use Vertical Pod Autoscaler (VPA)
   - Monitor and adjust based on usage

2. **Caching**
   - Implement Redis for session caching
   - Use CDN for static assets
   - Enable browser caching

3. **Database Optimization**
   - Connection pooling
   - Query optimization
   - Read replicas for read-heavy workloads

### Monitoring and Alerting

1. **Set up alerts in Prometheus**
   ```yaml
   # Example alert rules
   groups:
   - name: dao-platform
     rules:
     - alert: HighErrorRate
       expr: rate(dao_http_requests_total{status=~"5.."}[5m]) > 0.05
       for: 5m
   ```

2. **Log aggregation**
   - ELK stack or Loki for log aggregation
   - Structured logging
   - Log retention policies

3. **Distributed tracing**
   - Jaeger or Zipkin for request tracing
   - OpenTelemetry instrumentation

### Cost Optimization

1. **Right-sizing**
   - Monitor actual resource usage
   - Adjust requests/limits accordingly
   - Use spot instances for non-critical workloads

2. **Autoscaling**
   - HPA for pods
   - Cluster autoscaler for nodes
   - Schedule-based scaling

3. **Resource Cleanup**
   - Clean up unused resources
   - Implement TTL for temporary resources

## Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [WCAG Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Next.js Deployment](https://nextjs.org/docs/deployment)

## Support

For issues or questions:
1. Check the [troubleshooting section](#troubleshooting)
2. Review pod logs: `kubectl logs -n dao-platform -l app=dao-platform`
3. Open an issue on GitHub
4. Contact: support@dao-platform.local

---

**Version**: 1.0.0  
**Last Updated**: December 2024  
**Maintainer**: DAO Platform Team
