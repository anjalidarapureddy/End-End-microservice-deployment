# End-to-End Microservices Deployment

This repository contains a complete deployment solution for a microservices application with React frontend, Python backend (16 APIs), MongoDB, Redis, and Kafka.

## Repository Structure

```
.
├── architecture/
│   └── architecture-document.md
├── kubernetes/
│   ├── on-prem/          # Raw manifests (REFERENCE ONLY - not used)
│   ├── aws-eks/          # Raw manifests (REFERENCE ONLY - not used)
│   └── README.md         # Explanation of manifest usage
├── helm/
│   ├── frontend/
│   ├── backend/
│   ├── mongodb/
│   ├── redis/
│   └── kafka/
├── cicd/
│   └── jenkins/
│       ├── Jenkinsfile              # Main parameterized pipeline
│       ├── Jenkinsfile.dev          # DEV environment pipeline
│       ├── Jenkinsfile.prod         # PROD environment pipeline
│       ├── README.md                 # Jenkins setup guide
│       └── jenkins-config.xml        # Jenkins configuration template
├── monitoring/
│   ├── prometheus/
│   ├── grafana/
│   └── alerts/
└── logging/
    └── elk-stack/
├── scripts/
│   ├── build.sh
│   ├── deploy-dev.sh
│   ├── deploy-qat.sh
│   ├── deploy-uat.sh
│   ├── deploy-prod.sh
│   └── README.md
```

## Quick Start

1. Review the [Architecture Document](./architecture/architecture-document.md)
2. Configure environment-specific values in Helm charts
3. Set up CI/CD pipelines (Jenkins)
4. Use deployment scripts for easy deployments:
   ```bash
   # Build images
   ./scripts/build.sh all latest registry-dev.example.com
   
   # Deploy to DEV
   ./scripts/deploy-dev.sh all latest
   ```
5. Deploy monitoring and logging stack
6. Deploy application services

For detailed script usage, see [Scripts README](./scripts/README.md)

## Environment Details

- **DEV & QAT**: On-prem Kubernetes
- **UAT & PROD**: AWS EKS

## Prerequisites

- Kubernetes cluster (v1.24+)
- Helm 3.x
- kubectl configured
- Docker registry access
- AWS credentials (for UAT/PROD)

