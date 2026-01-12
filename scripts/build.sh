#!/bin/bash
# Build and push images for frontend and all backend services.
# Usage: ./build.sh [service] [tag] [registry]

set -euo pipefail

SERVICE=${1:-"all"}
TAG=${2:-"latest"}
REGISTRY=${3:-"myrepo"}  # keep aligned with Helm values (e.g., myrepo/frontend)
AWS_REGION=${AWS_REGION:-"us-east-1"}

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()   { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

docker_login() {
  log "Logging in to ${REGISTRY}"
  if [[ "${REGISTRY}" == *"amazonaws.com"* ]]; then
    aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${REGISTRY}" || {
      error "ECR login failed"; exit 1; }
  else
    if [ -n "${REGISTRY_USER:-}" ] && [ -n "${REGISTRY_PASS:-}" ]; then
      echo "${REGISTRY_PASS}" | docker login "${REGISTRY}" -u "${REGISTRY_USER}" --password-stdin || {
        error "Registry login failed"; exit 1; }
    else
      warn "Skipping login; REGISTRY_USER/REGISTRY_PASS not set (expected for public or pre-authenticated registries)"
    fi
  fi
}

build_image() {
  local service=$1
  local tag=$2
  [ -d "${service}" ] || { error "Service dir ${service} missing"; return 1; }
  log "Building ${service}:${tag}"
  docker build -t "${REGISTRY}/${service}:${tag}" -t "${REGISTRY}/${service}:latest" "./${service}"
}

push_image() {
  local service=$1
  local tag=$2
  log "Pushing ${service}:${tag}"
  docker push "${REGISTRY}/${service}:${tag}"
  docker push "${REGISTRY}/${service}:latest"
}

build_and_push() {
  local service=$1
  local tag=$2
  build_image "${service}" "${tag}"
  push_image "${service}" "${tag}"
}

main() {
  log "Service: ${SERVICE}"
  log "Tag: ${TAG}"
  log "Registry: ${REGISTRY}"

  docker_login

  BACKEND_SERVICES=("user-service" "product-service" "order-service" "notification-service" "analytics-service")

  case "${SERVICE}" in
    all)
      build_and_push "frontend" "${TAG}"
      for svc in "${BACKEND_SERVICES[@]}"; do
        build_and_push "${svc}" "${TAG}"
      done
      ;;
    frontend)
      build_and_push "frontend" "${TAG}"
      ;;
    backend)
      for svc in "${BACKEND_SERVICES[@]}"; do
        build_and_push "${svc}" "${TAG}"
      done
      ;;
    *)
      build_and_push "${SERVICE}" "${TAG}"
      ;;
  esac

  log "Builds completed."
}

main
