Promotion is artifact-based, not rebuild-based.

1. Code is built once.
2. Docker image tag = commit SHA.
3. Same image is deployed to DEV → QAT → UAT → PROD.
4. PROD requires manual approval.

Additional guardrails:

- RBAC: Ensure only authorized Jenkins roles/groups (e.g., `ops-admin`, `platform-team`) can run or approve PROD jobs.
- Typed confirmation: The pipeline requires the approver to type `DEPLOY_PROD` and provide a ticket ID (e.g., `JIRA-123`) before allowing a PROD deploy.
- Validation: The pipeline now validates required credentials (`kubeconfig-<env>`, `docker-registry-credentials` for on-prem, and `AWS_ACCOUNT_ID`/`AWS_REGION` for ECR) early and fails fast if missing.
