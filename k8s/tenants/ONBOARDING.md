# Tenant Onboarding Guide

## Overview

This guide walks through the process of onboarding a new tenant to the DAO Platform. Each tenant can have isolated configurations while sharing the underlying infrastructure.

## Prerequisites

- Access to the Kubernetes cluster
- `kubectl` configured with appropriate permissions
- Tenant information (domain, configuration requirements)
- Database access (if tenant requires isolated database)

## Onboarding Steps

### Step 1: Gather Tenant Information

Collect the following information from the tenant:

**Basic Information:**
- Tenant ID (slug): `example-tenant`
- Tenant Name: "Example Organization"
- Primary Domain: `example.com`
- Subdomain (optional): `example.dao-platform.local`

**Feature Requirements:**
- Required features (voting, proposals, treasury, etc.)
- Accessibility needs
- Compliance requirements (ADA, WCAG level, HIPAA, GDPR)
- Integration requirements

**Branding:**
- Primary color
- Accent color
- Logo (URL or upload)
- Theme preference

**Contact Information:**
- Support email
- Support phone (if applicable)
- Primary contact person

### Step 2: Create Tenant Configuration

1. Copy the tenant template:
```bash
cp k8s/tenants/tenant-template.yaml k8s/tenants/example-tenant-config.yaml
```

2. Edit the configuration file with tenant-specific values:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: tenant-example-config
  namespace: dao-platform
  labels:
    app: dao-platform
    tenant: example
    tenant-type: startup
data:
  TENANT_ID: "example"
  TENANT_NAME: "Example Organization"
  TENANT_DOMAIN: "example.com"
  TENANT_SUBDOMAIN: "example"
  
  # Feature flags
  ENABLE_PROPOSALS: "true"
  ENABLE_VOTING: "true"
  ENABLE_TREASURY: "true"
  
  # UI customization
  PRIMARY_COLOR: "#007bff"
  ACCENT_COLOR: "#28a745"
  THEME: "default"
  
  # Accessibility
  WCAG_LEVEL: "AA"
  SCREEN_READER_SUPPORT: "true"
  
  # Support
  SUPPORT_EMAIL: "support@example.com"
```

3. Apply the configuration:
```bash
kubectl apply -f k8s/tenants/example-tenant-config.yaml
```

### Step 3: Create Tenant Secrets

Create secrets for sensitive tenant data:

```bash
kubectl create secret generic tenant-example-secrets \
  --namespace=dao-platform \
  --from-literal=TENANT_ID='example' \
  --from-literal=TENANT_DB_URL='postgresql://user:password@postgres:5432/example_db' \
  --from-literal=TENANT_API_KEY="$(openssl rand -base64 32)" \
  --from-literal=STRIPE_API_KEY='sk_live_...' \
  --from-literal=SENDGRID_API_KEY='SG...'
```

Or create from a file:
```bash
# Create .env file with tenant secrets
cat > tenant-example.env <<EOF
TENANT_ID=example
TENANT_DB_URL=postgresql://user:password@postgres:5432/example_db
TENANT_API_KEY=your-api-key
STRIPE_API_KEY=sk_live_...
SENDGRID_API_KEY=SG...
EOF

kubectl create secret generic tenant-example-secrets \
  --namespace=dao-platform \
  --from-env-file=tenant-example.env

# Delete the file after creating the secret
rm tenant-example.env
```

### Step 4: Configure Database (If Isolated)

If the tenant requires an isolated database:

1. Create database:
```sql
CREATE DATABASE example_db;
CREATE USER example_user WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE example_db TO example_user;
```

2. Run migrations:
```bash
# Port-forward to application pod
kubectl port-forward -n dao-platform deployment/dao-platform 3000:3000

# Run migrations with tenant-specific connection
POSTGRES_URL='postgresql://example_user:secure_password@postgres:5432/example_db' \
  npx drizzle-kit push
```

### Step 5: Update Ingress for Tenant Domain

Edit `k8s/base/ingress.yaml` and add the tenant's domain:

```yaml
spec:
  tls:
  - hosts:
    - example.com
    - "*.example.com"
    secretName: example-com-tls
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: dao-platform
            port:
              number: 80
  - host: "*.example.com"
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

Apply the changes:
```bash
kubectl apply -f k8s/base/ingress.yaml
```

### Step 6: Configure DNS

Add DNS records for the tenant's domain:

```
example.com           A      <INGRESS-IP>
*.example.com         A      <INGRESS-IP>
example.com           AAAA   <INGRESS-IPv6>  (if using IPv6)
```

Get the ingress IP:
```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

### Step 7: Configure TLS Certificate

If using cert-manager for automatic TLS:

```bash
# cert-manager will automatically provision certificates based on ingress annotations
# Check certificate status:
kubectl get certificate -n dao-platform

# Check certificate details:
kubectl describe certificate example-com-tls -n dao-platform
```

If using manual certificates:
```bash
kubectl create secret tls example-com-tls \
  --namespace=dao-platform \
  --cert=path/to/cert.pem \
  --key=path/to/key.pem
```

### Step 8: Test Tenant Access

1. Wait for DNS propagation (can take up to 48 hours, usually minutes):
```bash
dig example.com
nslookup example.com
```

2. Test HTTPS access:
```bash
curl -I https://example.com
```

3. Verify tenant-specific configuration:
```bash
# Port-forward to test locally if DNS not yet propagated
kubectl port-forward -n dao-platform svc/dao-platform 8080:80

# Test with Host header
curl -H "Host: example.com" http://localhost:8080
```

4. Check application logs:
```bash
kubectl logs -n dao-platform -l app=dao-platform --tail=100
```

### Step 9: Set Up Monitoring

1. Verify tenant metrics are being scraped:
```bash
kubectl port-forward -n dao-platform svc/prometheus 9090:9090
# Open http://localhost:9090
# Query: dao_http_requests_total{tenant="example"}
```

2. Create tenant-specific Grafana dashboard (optional):
   - Import `k8s/dashboards/dao-tenant-metrics.json`
   - Select tenant from dropdown

### Step 10: Documentation and Handoff

Provide the tenant with:

1. **Access Information:**
   - Primary URL: `https://example.com`
   - Admin credentials (if applicable)
   - API keys and webhooks

2. **Configuration Summary:**
   - Enabled features
   - Accessibility settings
   - Integration endpoints
   - Rate limits

3. **Support Channels:**
   - Support email
   - Documentation links
   - Status page (if available)

4. **Training Materials:**
   - User guide
   - Admin guide
   - API documentation

## Tenant Management

### Updating Tenant Configuration

To update a tenant's configuration:

1. Edit the ConfigMap:
```bash
kubectl edit configmap tenant-example-config -n dao-platform
```

2. Restart pods to pick up changes:
```bash
kubectl rollout restart deployment/dao-platform -n dao-platform
```

### Viewing Tenant Metrics

```bash
# Port-forward Grafana
kubectl port-forward -n dao-platform svc/grafana 3000:3000

# Login to Grafana (admin/admin123)
# Navigate to "Tenant Metrics" dashboard
# Select tenant from dropdown
```

### Backing Up Tenant Data

```bash
# Backup tenant database
kubectl exec -n dao-platform deployment/postgres -- \
  pg_dump -U postgres -d example_db > example_tenant_backup.sql

# Backup tenant secrets
kubectl get secret tenant-example-secrets -n dao-platform -o yaml > example-secrets-backup.yaml

# Backup tenant ConfigMap
kubectl get configmap tenant-example-config -n dao-platform -o yaml > example-config-backup.yaml
```

### Offboarding a Tenant

1. Backup all tenant data
2. Remove DNS records
3. Delete tenant resources:
```bash
kubectl delete configmap tenant-example-config -n dao-platform
kubectl delete secret tenant-example-secrets -n dao-platform
```
4. Remove tenant domain from ingress
5. Drop tenant database (if isolated)

## Tenant Types and Templates

### Vocational Rehabilitation Agency (e.g., VR4Deaf)

Use the VR4Deaf template as a reference:
```bash
cp k8s/tenants/vr4deaf-configmap.yaml k8s/tenants/new-vr-agency-config.yaml
```

Key features:
- High accessibility (WCAG AAA)
- Video support with captions
- Sign language interpretation
- Screen reader optimization
- Job matching tools

### Startup/DAO

Standard template with:
- Proposals and voting
- Treasury management
- Member directory
- Basic accessibility (WCAG AA)

### Enterprise

Additional features:
- SSO integration
- Advanced compliance (SOC 2, HIPAA)
- Dedicated resources
- SLA monitoring

## Troubleshooting

### Tenant Not Accessible

1. Check DNS:
```bash
dig example.com
```

2. Check Ingress:
```bash
kubectl describe ingress dao-platform-ingress -n dao-platform
```

3. Check pod logs:
```bash
kubectl logs -n dao-platform -l app=dao-platform --tail=100
```

### Configuration Not Applied

1. Verify ConfigMap is created:
```bash
kubectl get configmap tenant-example-config -n dao-platform
```

2. Restart pods:
```bash
kubectl rollout restart deployment/dao-platform -n dao-platform
```

### Database Connection Issues

1. Test database connectivity:
```bash
kubectl run -it --rm debug --image=postgres:15 --restart=Never -- \
  psql postgresql://user:password@postgres:5432/example_db
```

2. Check secret values:
```bash
kubectl get secret tenant-example-secrets -n dao-platform -o jsonpath='{.data.TENANT_DB_URL}' | base64 -d
```

## Best Practices

1. **Security:**
   - Always use strong passwords
   - Rotate API keys regularly
   - Use least privilege access
   - Encrypt sensitive data at rest

2. **Documentation:**
   - Maintain tenant documentation
   - Document custom configurations
   - Keep contact information updated

3. **Monitoring:**
   - Set up alerts for tenant-specific metrics
   - Monitor resource usage
   - Track tenant growth

4. **Backup:**
   - Regular automated backups
   - Test restore procedures
   - Store backups securely

5. **Communication:**
   - Notify tenants of maintenance windows
   - Provide migration guides for updates
   - Maintain a changelog

## Additional Resources

- [Main Kubernetes README](../README.md)
- [Tenant Template](tenant-template.yaml)
- [VR4Deaf Example](vr4deaf-configmap.yaml)
- Tenant Dashboard: `k8s/dashboards/dao-tenant-metrics.json`

---

**Last Updated**: December 2024  
**Version**: 1.0.0
