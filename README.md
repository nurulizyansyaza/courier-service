# Courier Service

Orchestration repo for the **Courier Service** App Calculator. Ties together the core library, CLI app, Express API, and frontend dashboard with CI/CD and Docker.

## Architecture

```
courier-service/          ← this repo (CI/CD + Docker)
courier-service-core/     ← NPM package: cost, offers, shipment planning
courier-service-cli/      ← CLI app consuming the core package
courier-service-api/      ← Express REST API with security middleware
courier-service-frontend/ ← React/Vue/Svelte dashboard with API integration
```

### How They Connect

```
┌─────────────┐     ┌─────────────┐     ┌──────────────┐
│  Frontend    │────▶│   API       │────▶│   Core       │
│ (Vite SPA)  │proxy│ (Express)   │     │ (TS Library) │
└─────────────┘     └─────────────┘     └──────────────┘
                                              ▲    ▲
┌─────────────┐                               │    │
│   CLI       │───────────────────────────────┘    │
│ (Commander) │                                     │
└─────────────┘                                     │
                    ┌─────────────┐                  │
                    │  Frontend   │─── local fallback┘
                    │ (offline)   │
                    └─────────────┘
```

- **Frontend → API → Core**: Primary path. API provides rate limiting, validation, and security headers.
- **Frontend → Core**: Fallback when API is unreachable. Calculations run client-side.
- **CLI → Core**: Standalone. CLI reads stdin and outputs results directly.

## Setup

Clone all repos into the same parent directory:

```bash
mkdir courier-service-project && cd courier-service-project
git clone https://github.com/nurulizyansyaza/courier-service.git
git clone https://github.com/nurulizyansyaza/courier-service-core.git
git clone https://github.com/nurulizyansyaza/courier-service-cli.git
git clone https://github.com/nurulizyansyaza/courier-service-api.git
git clone https://github.com/nurulizyansyaza/courier-service-frontend.git
```

Install and build:

```bash
cd courier-service-core && npm ci && npm run build && cd ..
cd courier-service-cli && npm ci && cd ..
cd courier-service-api && npm ci && npm run build && cd ..
cd courier-service-frontend && npm ci && cd ..
```

## CI/CD

GitHub Actions workflow (`.github/workflows/ci.yml`) runs on push/PR:

1. **test-core** — installs and tests `courier-service-core` (Node 18 + 20)
2. **test-cli** — installs core + CLI, runs CLI tests (Node 18 + 20)
3. **test-api** — installs core + API, runs API tests (Node 18 + 20)
4. **test-frontend** — type-checks, tests, and builds the frontend (Node 20)
5. **test-system** — verifies CLI Problem 1/2 outputs and API cost endpoint

### Auto-Deploy to Staging

Each sub-repo has its own CI workflow that runs tests on push to `main`. On success, it fires a `repository_dispatch` event to this repo, which triggers the staging deployment pipeline:

```
Sub-repo push to main
  → Sub-repo CI runs tests
  → Tests pass → repository_dispatch (sub-repo-updated)
  → trigger-staging-deploy.yml (on main) receives event
  → Triggers deploy-staging.yml on the staging branch
  → Deploys to AWS (CloudFormation, ECS, S3, CloudFront)
```

**Setup required for auto-deploy:**

1. Create a fine-grained PAT at [github.com/settings/tokens](https://github.com/settings/tokens?type=beta):
   - Repository access: `nurulizyansyaza/courier-service`
   - Permissions: **Actions: Read & Write**, **Contents: Read & Write**
2. Add the PAT as `DEPLOY_TRIGGER_TOKEN` secret in each sub-repo (Settings → Secrets → Actions)

Manual deployment is also available via `workflow_dispatch`:

```bash
gh workflow run deploy-staging.yml --ref staging -f deploy_target=all
```

## Security

The API layer includes Express security middleware that protects all endpoints:

| Layer | Protection |
|-------|-----------|
| **Helmet** | Security headers against XSS, clickjacking, MIME sniffing |
| **CORS** | Origin whitelist (dev: localhost:5173, localhost:3000) |
| **Rate Limiting** | Global: 100 req/15min, Calculations: 30 req/min |
| **Zod Validation** | Schema-based input validation (type safety, length limits) |
| **Body Size Limit** | 100kb max request body |
| **Morgan** | HTTP request logging |

These protect against bots, DDoS, request flooding, and malformed input.

## Docker

```bash
# Build (from project root containing all repos)
docker build -f courier-service/Dockerfile -t courier-service .

# Run CLI - Problem 1
printf '100 3\nPKG1 5 5 OFR001\nPKG2 15 5 OFR002\nPKG3 10 100 OFR003\n' | docker run -i --entrypoint node courier-service courier-service-cli/bin/courier-service cost

# Run CLI - Problem 2
printf '100 5\nPKG1 50 30 OFR001\nPKG2 75 125 OFR008\nPKG3 175 100 OFR003\nPKG4 110 60 OFR002\nPKG5 155 95 NA\n2 70 200\n' | docker run -i --entrypoint node courier-service courier-service-cli/bin/courier-service delivery

# Run API server
docker run -p 3000:3000 --entrypoint node courier-service courier-service-api/dist/index.js
```

### Docker Compose

```bash
# Start the API server
docker compose up courier-api

# Run CLI interactively
printf '100 3\nPKG1 5 5 OFR001\nPKG2 15 5 OFR002\nPKG3 10 100 OFR003\n' | docker compose run courier-service cost
```

## Related Repos

- [courier-service-core](https://github.com/nurulizyansyaza/courier-service-core) — Core logic NPM package
- [courier-service-cli](https://github.com/nurulizyansyaza/courier-service-cli) — CLI application
- [courier-service-api](https://github.com/nurulizyansyaza/courier-service-api) — Express REST API
- [courier-service-frontend](https://github.com/nurulizyansyaza/courier-service-frontend) — Frontend dashboard
