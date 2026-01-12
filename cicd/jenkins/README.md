# Jenkins CI/CD Pipeline Configuration

This directory contains Jenkins pipeline configurations for deploying the microservices application across all environments.

## Pipeline Files

### 1. `Jenkinsfile`
Main pipeline file with parameterized deployment for all environments (DEV, QAT, UAT, PROD).

**Features:**
- Parameterized builds (environment, deployment type, image tag)
- Parallel builds for frontend and backend services
- Automated testing (unit and integration)
- Infrastructure and application deployment
- Smoke tests
- Notifications (Slack, Email)

### 2. `Jenkinsfile.dev`
Simplified pipeline for DEV environment with automatic triggers.

**Features:**
- SCM polling (every 5 minutes)
- Automatic builds on code changes
- Quick deployment to DEV

### 3. `Jenkinsfile.prod`
Production pipeline with enhanced safety features.

**Features:**
- Manual approval required
- Multiple deployment strategies (canary, rolling, blue-green)
- Security scanning (Trivy)
- Comprehensive health checks
- Extended timeouts

## Jenkins Setup

### Prerequisites

1. **Jenkins Plugins Required:**
   - Kubernetes Plugin
   - Docker Pipeline Plugin
   - Helm Plugin
   - Slack Notification Plugin
   - Email Extension Plugin
   - AWS Steps Plugin
   - AnsiColor Plugin

2. **Install Plugins:**
   ```bash
   # Via Jenkins UI: Manage Jenkins > Manage Plugins
   # Or via Jenkins CLI
   jenkins-plugin-cli --plugins \
     kubernetes:latest \
     docker-workflow:latest \
     pipeline-utility-steps:latest \
     slack:latest \
     email-ext:latest \
     aws-steps:latest \
     ansicolor:latest
   ```

### Credentials Setup

#### 1. Docker Registry Credentials (On-Prem)
- **ID**: `docker-registry-credentials`
- **Type**: Username with password
- **Username**: Your registry username
- **Password**: Your registry password

#### 2. Kubernetes Config Files
- **ID**: `kubeconfig-dev`
- **Type**: Secret file
- **File**: kubeconfig for DEV cluster

- **ID**: `kubeconfig-qat`
- **Type**: Secret file
- **File**: kubeconfig for QAT cluster

- **ID**: `kubeconfig-uat`
- **Type**: Secret file
- **File**: kubeconfig for UAT EKS cluster

- **ID**: `kubeconfig-prod`
- **Type**: Secret file
- **File**: kubeconfig for PROD EKS cluster

#### 3. AWS Credentials
- **ID**: `aws-credentials`
- **Type**: AWS Credentials
- **Access Key ID**: Your AWS access key
- **Secret Access Key**: Your AWS secret key

#### 4. Slack Webhook (Optional)
- **ID**: `slack-webhook`
- **Type**: Secret text
- **Secret**: Slack webhook URL

### Environment Variables

Configure the following in Jenkins:

1. **Global Environment Variables:**
   - `AWS_ACCOUNT_ID`: Your AWS account ID
   - `AWS_REGION`: AWS region (e.g., us-east-1)
   - `SLACK_WEBHOOK_URL`: Slack webhook URL (optional)
   - `DEPLOYMENT_TEAM_EMAIL`: Email for notifications

2. **Pipeline-Specific Variables:**
   - Registry URLs
   - Kubernetes context names
   - Ingress hosts

## Creating Jenkins Jobs

### Option 1: Multibranch Pipeline (Recommended)

1. Create a new **Multibranch Pipeline** job
2. Configure source:
   - **Branch Sources**: Git
   - **Project Repository**: Your Git repository URL
   - **Credentials**: Git credentials
   - **Behaviors**: Discover branches, Discover pull requests
3. **Build Configuration**:
   - **Mode**: By Jenkinsfile
   - **Script Path**: `cicd/jenkins/Jenkinsfile`

### Option 2: Pipeline Job

1. Create a new **Pipeline** job
2. **Pipeline Definition**:
   - **Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: Your Git repository
   - **Script Path**: `cicd/jenkins/Jenkinsfile`

### Option 3: Separate Jobs per Environment

1. **DEV Job**: Use `Jenkinsfile.dev`
2. **QAT Job**: Use `Jenkinsfile` with environment parameter
3. **UAT Job**: Use `Jenkinsfile` with environment parameter
4. **PROD Job**: Use `Jenkinsfile.prod`

## Usage

### Running the Main Pipeline

1. Navigate to Jenkins job
2. Click **Build with Parameters**
3. Select:
   - **ENVIRONMENT**: dev, qat, uat, or prod
   - **DEPLOYMENT_TYPE**: all, frontend, backend, or infrastructure
   - **IMAGE_TAG**: Optional (defaults to BUILD_NUMBER)
   - **SKIP_TESTS**: Check to skip tests
4. Click **Build**

### Running DEV Pipeline

The DEV pipeline runs automatically on code changes (SCM polling). You can also trigger it manually.

### Running PROD Pipeline

1. Navigate to PROD job
2. Click **Build with Parameters**
3. Select:
   - **DEPLOYMENT_STRATEGY**: canary, rolling, or blue-green
   - **APPROVE_DEPLOYMENT**: Check to auto-approve (not recommended)
4. Click **Build**
5. Approve the deployment when prompted

## Pipeline Stages

### 1. Checkout
- Checks out source code from Git
- Sets image tag based on build number and Git commit

### 2. Build Docker Images
- Builds frontend and backend service images in parallel
- Tags images with build number and commit SHA
- Pushes to registry (on-prem or ECR)

### 3. Run Tests
- **Unit Tests**: Runs pytest unit tests
- **Integration Tests**: Runs integration tests (QAT/UAT/PROD only)

### 4. Push Images
- Pushes all built images to registry
- Tags as both specific version and `latest`

### 5. Deploy Infrastructure
- Deploys MongoDB, Redis, and Kafka using Helm
- Waits for services to be ready

### 6. Deploy Applications
- Deploys frontend and backend services using Helm
- Configures environment-specific values
- Sets up autoscaling

### 7. Smoke Tests
- Runs basic health checks
- Validates deployments are working

## Deployment Strategies

### Rolling Update (Default)
- Gradual pod replacement
- Zero downtime
- Used for most deployments

### Canary Deployment
- Deploy new version to small subset
- Validate with limited traffic
- Gradually increase traffic
- Used for PROD critical services

### Blue-Green Deployment
- Deploy new version alongside old
- Switch traffic when validated
- Instant rollback capability
- Used for PROD major releases

## Monitoring Pipeline

### View Logs
- Click on build number
- View console output
- Check stage logs

### View Artifacts
- Test results (JUnit XML)
- Docker build logs
- Deployment manifests

### Notifications
- **Slack**: Sent to #deployments channel
- **Email**: Sent to deployment team
- **Status**: Success/Failure indicators

## Troubleshooting

### Build Failures

1. **Docker Build Fails:**
   - Check Dockerfile exists
   - Verify build context
   - Check registry credentials

2. **Helm Deploy Fails:**
   - Verify kubeconfig credentials
   - Check namespace exists
   - Verify Helm charts are valid
   - Check resource quotas

3. **Tests Fail:**
   - Review test output
   - Check test dependencies
   - Verify test environment

4. **Smoke Tests Fail:**
   - Check service health endpoints
   - Verify ingress configuration
   - Check DNS resolution

### Common Issues

**Issue**: Cannot connect to Kubernetes cluster
- **Solution**: Verify kubeconfig credentials and context

**Issue**: Docker login fails
- **Solution**: Check registry credentials and network connectivity

**Issue**: Helm chart not found
- **Solution**: Verify chart path and repository structure

**Issue**: Deployment timeout
- **Solution**: Increase timeout values or check resource availability

## Best Practices

1. **Use Multibranch Pipelines**: Automatically build branches and PRs
2. **Enable Notifications**: Stay informed of deployment status
3. **Use Approval Gates**: Require approval for production
4. **Monitor Build Times**: Optimize slow stages
5. **Keep Secrets Secure**: Use Jenkins credentials, never hardcode
6. **Version Images**: Use meaningful tags (build number + commit SHA)
7. **Test Before Deploy**: Run tests in CI before deployment
8. **Rollback Plan**: Have rollback procedures documented

## Advanced Configuration

### Custom Build Agents

Configure Jenkins agents with:
- Docker installed
- kubectl configured
- Helm installed
- AWS CLI configured (for EKS)

### Pipeline Libraries

Create shared libraries for:
- Common deployment functions
- Notification templates
- Health check utilities

### Webhooks

Configure Git webhooks to trigger builds:
- Push to main → Trigger UAT/PROD pipeline
- Push to develop → Trigger DEV pipeline
- Pull request → Trigger test pipeline

---

**Note**: Replace placeholder values (registry URLs, domain names, etc.) with your actual values.

