Kong declarative config

This directory includes a sample Kong declarative config and a ConfigMap manifest for the on-prem environment.

Files:
- `kong.yml` - human-editable declarative service/route config (for review and editing)
- `kong-configmap.yaml` - ConfigMap manifest that places `kong.yml` at `/kong/kong.yml` inside the Kong container (the `api-gateway` deployment mounts this ConfigMap).

How to apply:
1. Apply the ConfigMap:
   kubectl apply -f kong-configmap.yaml -n app-dev
2. Restart the Kong deployment so it reads the new declarative config:
   kubectl rollout restart deployment/api-gateway -n app-dev
3. Verify the services and routes via Kong Admin API (port 8001):
   curl http://<gateway-ip-or-service>:8001/services
   curl http://<gateway-ip-or-service>:8001/routes

Secrets and images:
- Templates for required secrets are in `kubernetes/on-prem/secrets/` (update with real values and apply).
- Images were replaced with default `registry.example.com/myteam/<service>:v1.0.0` — update as needed before production.

Notes:
- This sample uses paths prefixed with `/api/*` to match the existing Ingress which forwards `/api` to the gateway.
- If you prefer Ingress to route directly to services, replace the single `/api` -> `api-gateway` rule with per-service paths in `ingress.yaml`.
- Adjust service names and ports to match your cluster Service resources.

Additional notes:
- Example manifests for `auth-service`, `order-service`, `payment-service`, `product-service`, `notification-service`, and `analytics-service` have been added in this folder: `auth-deployment.yaml`, `order-deployment.yaml`, `payment-deployment.yaml`, `product-deployment.yaml`, `notification-deployment.yaml`, `analytics-deployment.yaml` (placeholders — update image tags, secrets, and resource values before applying).
- Secrets: create the required cluster secrets (for example `mongodb-secret`, `redis-secret`) following `DEPLOYMENT_GUIDE.md` or use a secrets manager with External Secrets Operator in non-dev environments.
- Placeholder images `your-registry/*` replaced with default `registry.example.com/myteam:<tag>` (change as needed).

Pre-deploy checklist (recommended):
1. Validate YAMLs: kubeval kubernetes/on-prem/*.yaml
2. Dry-run apply: kubectl apply -f kubernetes/on-prem/<file> -n app-dev --dry-run=client
3. Create required secrets (see `DEPLOYMENT_GUIDE.md`): mongodb-secret, redis-secret, etc.
4. Apply Kong ConfigMap: kubectl apply -f kong-configmap.yaml -n app-dev
5. Restart Kong: kubectl rollout restart deployment/api-gateway -n app-dev
6. Verify Kong services and routes: curl http://<gateway-ip-or-service>:8001/services && curl http://<gateway-ip-or-service>:8001/routes
7. Run basic smoke tests against API routes (e.g. /api/auth/health)

If you want, I can run YAML validation locally and add any fixes.