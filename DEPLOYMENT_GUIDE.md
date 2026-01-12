# End-to-End Deployment Guide

This guide provides step-by-step instructions for deploying the microservices application across all environments.

## Prerequisites

### On-Prem Kubernetes (DEV & QAT)
- Kubernetes cluster (v1.24+)
- kubectl configured
- Helm 3.x installed
- Nginx Ingress Controller
- Storage class configured
- Container registry access

### AWS EKS (UAT & PROD)
- AWS account with appropriate permissions
- EKS cluster created
- AWS CLI configured
- kubectl configured for EKS
- Helm 3.x installed
- AWS Load Balancer Controller
- ECR repositories created
- Route53 hosted zone (for DNS)

## Step 1: Prepare Secrets

### Create Kubernetes Secrets

```bash
# MongoDB credentials
kubectl create secret generic mongodb-secret \
  --from-literal=username=admin \
  --from-literal=password=your-secure-password \
  --from-literal=uri=mongodb://admin:your-secure-password@mongodb:27017 \
  --namespace app-dev

# Redis credentials
kubectl create secret generic redis-secret \
  --from-literal=password=your-redis-password \
  --namespace app-dev

# Application secrets
kubectl create secret generic app-secrets \
  --from-literal=api-key=your-api-key \
  --from-literal=jwt-secret=your-jwt-secret \
  --namespace app-dev
```

### AWS Secrets Manager (UAT/PROD)

```bash
# Store secrets in AWS Secrets Manager
aws secretsmanager create-secret \
  --name app/mongodb/credentials \
  --secret-string '{"username":"admin","password":"your-password"}'

aws secretsmanager create-secret \
  --name app/redis/credentials \
  --secret-string '{"password":"your-redis-password"}'
```

## Step 2: Deploy Infrastructure Components

### Deploy MongoDB

```bash
# DEV environment
helm install mongodb ./helm/mongodb \
  --namespace app-dev \
  --create-namespace \
  --set replicaCount=3 \
  --set persistence.size=20Gi \
  --set auth.enabled=true

# QAT environment
helm install mongodb ./helm/mongodb \
  --namespace app-qat \
  --create-namespace \
  --set replicaCount=3 \
  --set persistence.size=20Gi

# UAT environment (AWS EKS)
helm install mongodb ./helm/mongodb \
  --namespace app-uat \
  --create-namespace \
  --set replicaCount=3 \
  --set persistence.size=100Gi \
  --set persistence.storageClass=gp3

# PROD environment (AWS EKS)
helm install mongodb ./helm/mongodb \
  --namespace app-prod \
  --create-namespace \
  --set replicaCount=3 \
  --set persistence.size=500Gi \
  --set persistence.storageClass=gp3
```

### Deploy Redis

```bash
# DEV environment
helm install redis ./helm/redis \
  --namespace app-dev \
  --create-namespace \
  --set persistence.size=5Gi

# QAT environment
helm install redis ./helm/redis \
  --namespace app-qat \
  --create-namespace \
  --set persistence.size=5Gi

# UAT environment
helm install redis ./helm/redis \
  --namespace app-uat \
  --create-namespace \
  --set persistence.size=20Gi \
  --set persistence.storageClass=gp3

# PROD environment
helm install redis ./helm/redis \
  --namespace app-prod \
  --create-namespace \
  --set persistence.size=50Gi \
  --set persistence.storageClass=gp3
```

### Deploy Kafka

```bash
# DEV environment
helm install kafka ./helm/kafka \
  --namespace app-dev \
  --create-namespace \
  --set kafka.replicas=3 \
  --set kafka.persistence.size=50Gi

# QAT environment
helm install kafka ./helm/kafka \
  --namespace app-qat \
  --create-namespace \
  --set kafka.replicas=3 \
  --set kafka.persistence.size=50Gi

# UAT environment
helm install kafka ./helm/kafka \
  --namespace app-uat \
  --create-namespace \
  --set kafka.replicas=3 \
  --set kafka.persistence.size=200Gi \
  --set kafka.persistence.storageClass=gp3

# PROD environment
helm install kafka ./helm/kafka \
  --namespace app-prod \
  --create-namespace \
  --set kafka.replicas=3 \
  --set kafka.persistence.size=500Gi \
  --set kafka.persistence.storageClass=gp3
```

## Step 3: Deploy Application Services

### Deploy Frontend

```bash
# DEV environment
helm install frontend ./helm/frontend \
  --namespace app-dev \
  --set image.repository=your-registry/frontend \
  --set image.tag=latest \
  --set env.ENVIRONMENT=dev \
  --set env.API_BASE_URL=http://api-gateway.app-dev.svc.cluster.local \
  --set autoscaling.minReplicas=3 \
  --set autoscaling.maxReplicas=10 \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=app-dev.example.com

# QAT environment
helm install frontend ./helm/frontend \
  --namespace app-qat \
  --set image.repository=your-registry/frontend \
  --set image.tag=latest \
  --set env.ENVIRONMENT=qat \
  --set autoscaling.minReplicas=3 \
  --set autoscaling.maxReplicas=10

# UAT environment (AWS EKS)
helm install frontend ./helm/frontend \
  --namespace app-uat \
  --set image.repository=${ECR_REGISTRY}/frontend \
  --set image.tag=latest \
  --set env.ENVIRONMENT=uat \
  --set autoscaling.minReplicas=5 \
  --set autoscaling.maxReplicas=20 \
  --set ingress.className=alb \
  --set ingress.hosts[0].host=app-uat.example.com

# PROD environment (AWS EKS)
helm install frontend ./helm/frontend \
  --namespace app-prod \
  --set image.repository=${ECR_REGISTRY}/frontend \
  --set image.tag=latest \
  --set env.ENVIRONMENT=prod \
  --set autoscaling.minReplicas=10 \
  --set autoscaling.maxReplicas=50 \
  --set ingress.className=alb \
  --set ingress.hosts[0].host=app-prod.example.com
```

### Deploy Backend Services

```bash
# Deploy all backend services
for service in user-service product-service order-service notification-service analytics-service; do
  # DEV
  helm install $service ./helm/backend \
    --namespace app-dev \
    --set serviceName=$service \
    --set image.repository=your-registry/$service \
    --set image.tag=latest \
    --set env.ENVIRONMENT=dev \
    --set env.MONGODB_URI=mongodb://mongodb.app-dev.svc.cluster.local:27017 \
    --set env.REDIS_HOST=redis.app-dev.svc.cluster.local \
    --set env.KAFKA_BROKERS=kafka-0.kafka.app-dev.svc.cluster.local:9092 \
    --set autoscaling.minReplicas=2 \
    --set autoscaling.maxReplicas=10

  # QAT
  helm install $service ./helm/backend \
    --namespace app-qat \
    --set serviceName=$service \
    --set image.repository=your-registry/$service \
    --set image.tag=latest \
    --set env.ENVIRONMENT=qat \
    --set autoscaling.minReplicas=3 \
    --set autoscaling.maxReplicas=10

  # UAT
  helm install $service ./helm/backend \
    --namespace app-uat \
    --set serviceName=$service \
    --set image.repository=${ECR_REGISTRY}/$service \
    --set image.tag=latest \
    --set env.ENVIRONMENT=uat \
    --set autoscaling.minReplicas=3 \
    --set autoscaling.maxReplicas=15

  # PROD
  helm install $service ./helm/backend \
    --namespace app-prod \
    --set serviceName=$service \
    --set image.repository=${ECR_REGISTRY}/$service \
    --set image.tag=latest \
    --set env.ENVIRONMENT=prod \
    --set autoscaling.minReplicas=5 \
    --set autoscaling.maxReplicas=20
done
```

## Step 4: Deploy Monitoring Stack

### Create Monitoring Namespace

```bash
kubectl create namespace monitoring
```

### Deploy Prometheus

```bash
# Apply Prometheus configuration
kubectl apply -f monitoring/prometheus/prometheus-config.yaml

# Deploy Prometheus
kubectl apply -f monitoring/prometheus/prometheus-deployment.yaml
```

### Deploy Grafana

```bash
# Create Grafana secret
kubectl create secret generic grafana-secret \
  --from-literal=admin-user=admin \
  --from-literal=admin-password=your-password \
  --namespace monitoring

# Deploy Grafana
kubectl apply -f monitoring/grafana/grafana-deployment.yaml
```

### Deploy AlertManager

```bash
# Create AlertManager secret with Slack/PagerDuty webhooks
kubectl create secret generic alertmanager-secret \
  --from-literal=slack-webhook-url=your-slack-webhook \
  --from-literal=pagerduty-key=your-pagerduty-key \
  --namespace monitoring

# Apply AlertManager configuration
kubectl apply -f monitoring/alerts/alertmanager-config.yaml
kubectl apply -f monitoring/alerts/alert-rules.yaml
```

## Step 5: Deploy Logging Stack

### Create Logging Namespace

```bash
kubectl create namespace logging
```

### Deploy Elasticsearch

```bash
kubectl apply -f logging/elk-stack/elasticsearch-statefulset.yaml
```

### Deploy Kibana

```bash
kubectl apply -f logging/elk-stack/kibana-deployment.yaml
```

### Deploy Fluentd

```bash
# Apply Fluentd configuration
kubectl apply -f logging/elk-stack/fluentd-config.yaml

# Deploy Fluentd DaemonSet
kubectl apply -f logging/elk-stack/fluentd-daemonset.yaml
```

## Step 6: Configure CI/CD

### Jenkins Setup

1. **Install Required Plugins:**
   - Kubernetes Plugin
   - Docker Pipeline Plugin
   - Helm Plugin
   - Slack Notification Plugin
   - Email Extension Plugin
   - AWS Steps Plugin

2. **Configure Credentials:**
   - Docker registry credentials (`docker-registry-credentials`)
   - Kubernetes config files (`kubeconfig-dev`, `kubeconfig-qat`, `kubeconfig-uat`, `kubeconfig-prod`)
   - AWS credentials (`aws-credentials`)
   - Slack webhook (optional)

3. **Set Global Environment Variables:**
   - `AWS_ACCOUNT_ID`
   - `AWS_REGION`
   - `REGISTRY_DEV`
   - `DEPLOYMENT_TEAM_EMAIL`

4. **Create Jenkins Jobs:**
   - **Multibranch Pipeline**: For automatic builds on branches
   - **Pipeline Job**: For manual parameterized deployments
   - Use `cicd/jenkins/Jenkinsfile` as the pipeline script

5. **Configure Pipeline:**
   - Set up SCM (Git repository)
   - Configure build triggers (SCM polling or webhooks)
   - Set default parameters

For detailed Jenkins setup instructions, see `cicd/jenkins/README.md`

## Step 7: Verify Deployment

### Check Pod Status

```bash
# Check all pods
kubectl get pods -n app-dev
kubectl get pods -n app-qat
kubectl get pods -n app-uat
kubectl get pods -n app-prod
```

### Check Services

```bash
kubectl get svc -n app-dev
kubectl get ingress -n app-dev
```

### Check HPA

```bash
kubectl get hpa -n app-dev
```

### Access Applications

- Frontend: `https://app-dev.example.com`
- Grafana: Port-forward to access `kubectl port-forward -n monitoring svc/grafana 3000:3000`
- Kibana: Port-forward to access `kubectl port-forward -n logging svc/kibana 5601:5601`

## Step 8: Post-Deployment Tasks

### Initialize MongoDB Replica Set

```bash
kubectl exec -it mongodb-0 -n app-dev -- mongo --eval "rs.initiate()"
```

### Create Kafka Topics

```bash
kubectl exec -it kafka-kafka-0 -n app-dev -- kafka-topics --create \
  --bootstrap-server localhost:9092 \
  --replication-factor 3 \
  --partitions 3 \
  --topic user-events

kubectl exec -it kafka-kafka-0 -n app-dev -- kafka-topics --create \
  --bootstrap-server localhost:9092 \
  --replication-factor 3 \
  --partitions 3 \
  --topic order-events
```

### Run Smoke Tests

```bash
# Test frontend
curl https://app-dev.example.com/health

# Test backend APIs
curl https://app-dev.example.com/api/v1/health
```

## Troubleshooting

### Pods Not Starting

```bash
# Check pod logs
kubectl logs <pod-name> -n <namespace>

# Check pod events
kubectl describe pod <pod-name> -n <namespace>
```

### Services Not Accessible

```bash
# Check service endpoints
kubectl get endpoints -n <namespace>

# Check ingress
kubectl describe ingress -n <namespace>
```

### HPA Not Scaling

```bash
# Check HPA status
kubectl describe hpa <hpa-name> -n <namespace>

# Check metrics
kubectl top pods -n <namespace>
```

## Maintenance

### Update Application

```bash
# Update image tag
helm upgrade frontend ./helm/frontend \
  --namespace app-dev \
  --set image.tag=new-tag
```

### Rollback

```bash
# Rollback to previous version
helm rollback frontend -n app-dev
```

### Backup

```bash
# MongoDB backup
kubectl exec -it mongodb-0 -n app-dev -- mongodump --out=/backup

# Redis backup
kubectl exec -it redis-0 -n app-dev -- redis-cli --rdb /backup/dump.rdb
```

---

**Note**: Replace placeholder values (registry URLs, passwords, domains) with actual values for your environment.

