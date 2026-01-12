# Jenkins CI/CD Quick Start Guide

## Quick Setup (5 Minutes)

### 1. Install Jenkins Plugins

```bash
# Via Jenkins UI: Manage Jenkins > Manage Plugins > Available
# Install these plugins:
- Kubernetes Plugin
- Docker Pipeline Plugin  
- Helm Plugin
- Slack Notification Plugin
- Email Extension Plugin
- AWS Steps Plugin
```

### 2. Configure Credentials

Go to **Manage Jenkins > Credentials > System > Global credentials**

#### Docker Registry (On-Prem)
- **Kind**: Username with password
- **ID**: `docker-registry-credentials`
- **Username**: Your registry username
- **Password**: Your registry password

#### Kubernetes Configs
- **Kind**: Secret file
- **ID**: `kubeconfig-dev`
- **File**: Upload your DEV kubeconfig

Repeat for: `kubeconfig-qat`, `kubeconfig-uat`, `kubeconfig-prod`

#### AWS Credentials
- **Kind**: AWS Credentials
- **ID**: `aws-credentials`
- **Access Key ID**: Your AWS access key
- **Secret Access Key**: Your AWS secret key

### 3. Set Global Environment Variables

Go to **Manage Jenkins > Configure System > Global properties**

Add:
- `AWS_ACCOUNT_ID`: Your AWS account ID
- `AWS_REGION`: us-east-1
- `REGISTRY_DEV`: registry-dev.example.com
- `DEPLOYMENT_TEAM_EMAIL`: your-team@example.com

### 4. Create Pipeline Job

1. **New Item** > **Pipeline**
2. **Pipeline Definition**: Pipeline script from SCM
3. **SCM**: Git
4. **Repository URL**: Your Git repository
5. **Script Path**: `cicd/jenkins/Jenkinsfile`
6. **Save**

### 5. Run Your First Build

1. Click **Build with Parameters**
2. Select:
   - **ENVIRONMENT**: dev
   - **DEPLOYMENT_TYPE**: all
3. Click **Build**

## Common Commands

### Build for DEV
```
Build with Parameters:
- ENVIRONMENT: dev
- DEPLOYMENT_TYPE: all
```

### Build for PROD
```
Build with Parameters:
- ENVIRONMENT: prod
- DEPLOYMENT_TYPE: all
- DEPLOYMENT_STRATEGY: canary
- APPROVE_DEPLOYMENT: false (requires manual approval)
```

### Deploy Only Frontend
```
Build with Parameters:
- ENVIRONMENT: uat
- DEPLOYMENT_TYPE: frontend
```

### Deploy Only Infrastructure
```
Build with Parameters:
- ENVIRONMENT: qat
- DEPLOYMENT_TYPE: infrastructure
```

## Pipeline Stages Overview

1. **Checkout** - Gets code from Git
2. **Build** - Builds Docker images (parallel)
3. **Test** - Runs unit/integration tests
4. **Push** - Pushes images to registry
5. **Deploy Infrastructure** - Deploys MongoDB, Redis, Kafka
6. **Deploy Applications** - Deploys frontend and backend
7. **Smoke Tests** - Validates deployment

## Troubleshooting

### Build Fails at Docker Login
- Check registry credentials
- Verify network connectivity

### Build Fails at Helm Deploy
- Verify kubeconfig credentials
- Check namespace exists
- Verify Helm charts are valid

### Tests Fail
- Check test dependencies installed
- Review test output in console

## Next Steps

- Set up webhooks for automatic builds
- Configure Slack notifications
- Set up approval gates for production
- Review full documentation in `README.md`

