#!/bin/bash
# Deploy to UAT (AWS EKS). Deploys infra + frontend + all backend services.
# Usage: ./deploy-uat.sh [service] [image-tag]

set -euo pipefail

SERVICE=${1:-"all"}
IMAGE_TAG=${2:-"latest"}
NAMESPACE="app-uat"
KUBECTL_CONTEXT="uat-eks-cluster"
AWS_REGION=${AWS_REGION:-"us-east-1"}
ECR_REGISTRY=""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()   { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_prereqs() {
  command -v kubectl >/dev/null 2>&1 || { error "kubectl missing"; exit 1; }
  command -v helm >/dev/null 2>&1    || { error "helm missing"; exit 1; }
  command -v aws >/dev/null 2>&1     || { error "aws CLI missing"; exit 1; }

  if [ -z "${AWS_ACCOUNT_ID:-}" ]; then error "Set AWS_ACCOUNT_ID"; exit 1; fi
  ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

  if [ -n "${EKS_CLUSTER_NAME_UAT:-}" ]; then
    log "Updating kubeconfig for cluster ${EKS_CLUSTER_NAME_UAT}"
    aws eks update-kubeconfig --name "${EKS_CLUSTER_NAME_UAT}" --region "${AWS_REGION}"
  fi

  kubectl config use-context "${KUBECTL_CONTEXT}" >/dev/null 2>&1 || {
    error "Cannot switch to context ${KUBECTL_CONTEXT}"; exit 1; }

  aws sts get-caller-identity >/dev/null 2>&1 || { error "AWS creds invalid"; exit 1; }
}

deploy_infra() {
  log "Deploying MongoDB"
  helm upgrade --install mongodb ./helm/mongodb \
    --namespace "${NAMESPACE}" --create-namespace \
    --set replicaCount=3 \
    --set persistence.size=100Gi \
    --set persistence.storageClass=gp3 \
    --wait --timeout 15m || warn "MongoDB may not be ready"

  log "Deploying Redis"
  helm upgrade --install redis ./helm/redis \
    --namespace "${NAMESPACE}" --create-namespace \
    --set persistence.size=20Gi \
    --set persistence.storageClass=gp3 \
    --wait --timeout 10m || warn "Redis may not be ready"

  log "Deploying Kafka"
  helm upgrade --install kafka ./helm/kafka \
    --namespace "${NAMESPACE}" --create-namespace \
    --set kafka.replicas=3 \
    --set kafka.persistence.size=200Gi \
    --set kafka.persistence.storageClass=gp3 \
    --wait --timeout 15m || warn "Kafka may not be ready"
}

deploy_frontend() {
  log "Deploying frontend"
  helm upgrade --install frontend ./helm/frontend \
    --namespace "${NAMESPACE}" --create-namespace \
    -f ./helm/frontend/values-uat.yaml \
    --set image.tag="${IMAGE_TAG}" \
    --set ingress.className=alb \
    --wait --timeout 10m
}

deploy_backend() {
  BACKEND_SERVICES=("user-service" "product-service" "order-service" "notification-service" "analytics-service")
  for svc in "${BACKEND_SERVICES[@]}"; do
    log "Deploying ${svc}"
    helm upgrade --install "${svc}" ./helm/backend \
      --namespace "${NAMESPACE}" --create-namespace \
      -f ./helm/backend/values-uat.yaml \
      --set serviceName="${svc}" \
      --set image.tag="${IMAGE_TAG}" \
      --wait --timeout 10m
  done
}

wait_ready() {
  log "Waiting for workloads to be ready"
  kubectl wait --for=condition=available --timeout=300s deployment/frontend -n "${NAMESPACE}" || warn "Frontend not ready yet"
  for svc in user-service product-service order-service notification-service analytics-service; do
    kubectl wait --for=condition=available --timeout=300s deployment/${svc} -n "${NAMESPACE}" || warn "${svc} not ready yet"
  done
}

smoke() {
  INGRESS_HOST=$(kubectl get ingress -n "${NAMESPACE}" -o jsonpath='{.items[0].spec.rules[0].host}' 2>/dev/null || echo "")
  if [ -n "${INGRESS_HOST}" ]; then
    log "Smoke: GET https://${INGRESS_HOST}/health"
    curl -f "https://${INGRESS_HOST}/health" || warn "Health check failed"
  else
    warn "Ingress not found; skipping smoke"
  fi
}

main() {
  log "Deploying to UAT namespace ${NAMESPACE}"
  log "Service: ${SERVICE} | Tag: ${IMAGE_TAG}"
  check_prereqs

  [ "${SERVICE}" = "all" ] || [ "${SERVICE}" = "infrastructure" ] && deploy_infra
  [ "${SERVICE}" = "all" ] || [ "${SERVICE}" = "frontend" ]      && deploy_frontend
  [ "${SERVICE}" = "all" ] || [ "${SERVICE}" = "backend" ]       && deploy_backend

  wait_ready
  smoke
  log "UAT deployment complete. Endpoint: https://app-uat.example.com"
}

main
