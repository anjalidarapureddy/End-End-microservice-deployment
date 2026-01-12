#!/bin/bash
# Deploy to QAT (on-prem). Deploys infra + frontend + all backend services.
# Usage: ./deploy-qat.sh [service] [image-tag]

set -euo pipefail

SERVICE=${1:-"all"}
IMAGE_TAG=${2:-"latest"}
NAMESPACE="app-qat"
KUBECTL_CONTEXT="qat-cluster"
REGISTRY="registry-dev.example.com"

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
  kubectl config use-context "${KUBECTL_CONTEXT}" >/dev/null 2>&1 || {
    error "Cannot switch to context ${KUBECTL_CONTEXT}"; exit 1; }
}

deploy_infra() {
  log "Deploying MongoDB"
  helm upgrade --install mongodb ./helm/mongodb \
    --namespace "${NAMESPACE}" --create-namespace \
    --set replicaCount=3 \
    --set persistence.size=20Gi \
    --wait --timeout 10m || warn "MongoDB may not be ready"

  log "Deploying Redis"
  helm upgrade --install redis ./helm/redis \
    --namespace "${NAMESPACE}" --create-namespace \
    --set persistence.size=5Gi \
    --wait --timeout 5m || warn "Redis may not be ready"

  log "Deploying Kafka"
  helm upgrade --install kafka ./helm/kafka \
    --namespace "${NAMESPACE}" --create-namespace \
    --set kafka.replicas=3 \
    --set kafka.persistence.size=50Gi \
    --wait --timeout 10m || warn "Kafka may not be ready"
}

deploy_frontend() {
  log "Deploying frontend"
  helm upgrade --install frontend ./helm/frontend \
    --namespace "${NAMESPACE}" --create-namespace \
    -f ./helm/frontend/values-qat.yaml \
    --set image.tag="${IMAGE_TAG}" \
    --wait --timeout 10m
}

deploy_backend() {
  BACKEND_SERVICES=("user-service" "product-service" "order-service" "notification-service" "analytics-service")
  for svc in "${BACKEND_SERVICES[@]}"; do
    log "Deploying ${svc}"
    helm upgrade --install "${svc}" ./helm/backend \
      --namespace "${NAMESPACE}" --create-namespace \
      -f ./helm/backend/values-qat.yaml \
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
    log "Smoke: GET http://${INGRESS_HOST}/health"
    curl -f "http://${INGRESS_HOST}/health" || warn "Health check failed"
  else
    warn "Ingress not found; skipping smoke"
  fi
}

main() {
  log "Deploying to QAT namespace ${NAMESPACE}"
  log "Service: ${SERVICE} | Tag: ${IMAGE_TAG}"
  check_prereqs

  [ "${SERVICE}" = "all" ] || [ "${SERVICE}" = "infrastructure" ] && deploy_infra
  [ "${SERVICE}" = "all" ] || [ "${SERVICE}" = "frontend" ]      && deploy_frontend
  [ "${SERVICE}" = "all" ] || [ "${SERVICE}" = "backend" ]       && deploy_backend

  wait_ready
  smoke
  log "QAT deployment complete. Endpoint: http://app-qat.example.com"
}

main
