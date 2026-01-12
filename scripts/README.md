# Deployment Scripts

This directory contains shell scripts for building and deploying the microservices application to different environments.

## Scripts Overview

### `build.sh`
Builds Docker images for frontend and backend services.

**Usage:**
```bash
# Build all services
./build.sh [service] [tag] [registry]

# Examples:
./build.sh all latest registry-dev.example.com
./build.sh frontend v1.0.0 registry-dev.example.com
./build.sh user-service dev-latest registry-dev.example.com
```

**Environment Variables:**
- `REGISTRY_USER`: Username for on-prem registry (required for non-ECR)
- `REGISTRY_PASS`: Password for on-prem registry (required for non-ECR)
- `AWS_REGION`: AWS region for ECR (default: us-east-1)

### `deploy-dev.sh`
Deploys to DEV environment (On-Prem Kubernetes).

**Usage:**
```bash
./deploy-dev.sh [service] [image-tag]

# Examples:
./deploy-dev.sh all latest
./deploy-dev.sh frontend v1.0.0
./deploy-dev.sh backend dev-latest
./deploy-dev.sh infrastructure
```

**Prerequisites:**
- kubectl configured with `dev-cluster` context
- helm installed
- Docker images built and pushed to registry

### `deploy-qat.sh`
Deploys to QAT environment (On-Prem Kubernetes).

**Usage:**
```bash
./deploy-qat.sh [service] [image-tag]

# Examples:
./deploy-qat.sh all latest
./deploy-qat.sh frontend qat-release
```

**Prerequisites:**
- kubectl configured with `qat-cluster` context
- helm installed
- Docker images built and pushed to registry

### `deploy-uat.sh`
Deploys to UAT environment (AWS EKS).

**Usage:**
```bash
./deploy-uat.sh [service] [image-tag]

# Examples:
./deploy-uat.sh all latest
./deploy-uat.sh frontend uat-release
```

**Prerequisites:**
- AWS CLI configured
- kubectl configured for EKS
- helm installed
- Docker images built and pushed to ECR
- Environment variables:
  - `AWS_ACCOUNT_ID`: Your AWS account ID
  - `AWS_REGION`: AWS region (default: us-east-1)
  - `EKS_CLUSTER_NAME_UAT`: UAT EKS cluster name (optional)

### `deploy-prod.sh`
Deploys to PROD environment (AWS EKS) with safety checks.

**Usage:**
```bash
./deploy-prod.sh [service] [image-tag] [strategy]

# Examples:
./deploy-prod.sh all latest rolling
./deploy-prod.sh frontend v1.0.0 canary
./deploy-prod.sh backend prod-release blue-green
```

**Deployment Strategies:**
- `rolling` (default): Rolling update deployment
- `canary`: Canary deployment with gradual traffic shift
- `blue-green`: Blue-green deployment with instant switch

**Prerequisites:**
- AWS CLI configured
- kubectl configured for EKS
- helm installed
- Docker images built and pushed to ECR
- Environment variables:
  - `AWS_ACCOUNT_ID`: Your AWS account ID
  - `AWS_REGION`: AWS region (default: us-east-1)
  - `EKS_CLUSTER_NAME_PROD`: PROD EKS cluster name (optional)

**Safety Features:**
- Requires manual confirmation before deployment
- Comprehensive health checks
- Extended timeouts for production workloads

## Quick Start

### 1. Build Images
```bash
# Set registry credentials (for on-prem)
export REGISTRY_USER="your-username"
export REGISTRY_PASS="your-password"

# Build all services
./build.sh all latest registry-dev.example.com
```

### 2. Deploy to DEV
```bash
# Deploy everything
./deploy-dev.sh all latest

# Deploy only frontend
./deploy-dev.sh frontend latest

# Deploy only backend
./deploy-dev.sh backend latest

# Deploy only infrastructure
./deploy-dev.sh infrastructure
```

### 3. Deploy to PROD
```bash
# Set AWS credentials
export AWS_ACCOUNT_ID="123456789012"
export AWS_REGION="us-east-1"

# Build and push to ECR
./build.sh all prod-release ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Deploy with rolling update
./deploy-prod.sh all prod-release rolling

# Deploy with canary strategy
./deploy-prod.sh frontend prod-release canary
```

## Service Options

The `service` parameter accepts:
- `all`: Deploy/build all services
- `frontend`: Frontend only
- `backend`: All backend services
- `infrastructure`: MongoDB, Redis, Kafka only
- Individual service name: `user-service`, `product-service`, etc.

## Environment Variables

### Common Variables
- `REGISTRY_USER`: Docker registry username (on-prem)
- `REGISTRY_PASS`: Docker registry password (on-prem)
- `AWS_REGION`: AWS region (default: us-east-1)

### AWS-Specific Variables
- `AWS_ACCOUNT_ID`: AWS account ID (required for UAT/PROD)
- `EKS_CLUSTER_NAME_UAT`: UAT EKS cluster name
- `EKS_CLUSTER_NAME_PROD`: PROD EKS cluster name

## Error Handling

All scripts include:
- Error checking with `set -e`
- Colored output for better visibility
- Prerequisites validation
- Graceful error messages
- Exit codes for CI/CD integration

## Integration with CI/CD

These scripts can be used in:
- Jenkins pipelines
- GitHub Actions
- GitLab CI
- Local development workflows

Example Jenkins integration:
```groovy
stage('Deploy') {
    steps {
        sh './scripts/deploy-dev.sh all ${BUILD_NUMBER}'
    }
}
```

## Troubleshooting

### Build Fails
- Check Docker is running
- Verify registry credentials
- Check network connectivity

### Deploy Fails
- Verify kubectl context is correct
- Check Helm charts are valid
- Verify namespace exists
- Check resource quotas

### EKS Deploy Fails
- Verify AWS credentials
- Check EKS cluster is accessible
- Verify IAM permissions
- Check kubectl is configured for EKS

## Best Practices

1. **Always test in DEV first**: Deploy to DEV before QAT/UAT/PROD
2. **Use version tags**: Don't use `latest` in production
3. **Verify before deploying**: Check images are built and pushed
4. **Monitor deployments**: Watch logs during deployment
5. **Have rollback plan**: Know how to rollback if needed

## Examples

### Complete Deployment Workflow

```bash
# 1. Build images
./build.sh all v1.2.3 registry-dev.example.com

# 2. Deploy to DEV
./deploy-dev.sh all v1.2.3

# 3. Test in DEV
# ... run tests ...

# 4. Deploy to QAT
./deploy-qat.sh all v1.2.3

# 5. Deploy to UAT
export AWS_ACCOUNT_ID="123456789012"
./deploy-uat.sh all v1.2.3

# 6. Deploy to PROD (with canary)
./deploy-prod.sh all v1.2.3 canary
```

### Partial Deployment

```bash
# Deploy only frontend to DEV
./deploy-dev.sh frontend latest

# Deploy only backend to PROD
./deploy-prod.sh backend prod-release rolling
```

---

**Note**: Make sure scripts are executable (`chmod +x scripts/*.sh`) and update placeholder values (registry URLs, domain names) with your actual values.

