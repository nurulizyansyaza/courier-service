# Courier Service

Orchestration repo for the **Courier Service** App Calculator. Ties together the core library, CLI app, Express API and frontend dashboard with CI/CD, Docker and AWS deployment.

## Architecture

```
courier-service/          ← this repo (CI/CD + Docker + AWS infra)
courier-service-core/     ← NPM package: cost, offers, shipment planning (147 tests)
courier-service-cli/      ← Interactive CLI with Ink TUI (113 tests)
courier-service-api/      ← Express REST API with security middleware (33 tests)
courier-service-frontend/ ← React/Vue/Svelte dashboard with API integration (248 tests)
```

### How They Connect

```mermaid
graph LR
    Frontend["Frontend<br/>(Vite SPA)"] -->|"/api/* proxy"| API["API<br/>(Express)"]
    API --> Core["Core<br/>(TS Library)"]
    CLI["CLI<br/>(Ink TUI)"] --> Core
    CLI -.->|"--api-url"| API
    Frontend -.->|"local fallback"| Core
```

- **Frontend → API → Core**: Primary path. API provides rate limiting, validation, and security headers.
- **Frontend → Core**: Fallback when API is unreachable. Calculations run client-side.
- **CLI → API → Core**: CLI tries API first (default `http://localhost:3000`), falls back to local core.
- **CLI → Core**: With `--local` flag, CLI skips API and runs calculations directly via core.

### Core Library Modules

```mermaid
graph TB
    subgraph Core["@courier-service-core"]
        Parser["parser.ts<br/>Input parsing &amp; validation"]
        Cost["costCalculator.ts<br/>Cost &amp; discount calculation"]
        Planner["deliveryPlanner.ts<br/>Vehicle assignment &amp; scheduling"]
        Output["outputParser.ts<br/>Result formatting &amp; parsing"]
        Transit["transitHelpers.ts<br/>Transit conflict resolution"]
        Constants["constants.ts<br/>Shared multipliers &amp; regex"]
        Validators["validators.ts<br/>Offer code &amp; input validation"]
    end

    Parser --> Constants
    Parser --> Validators
    Cost --> Constants
    Planner --> Transit
    Planner --> Constants
    Output --> Transit
```

### Cost Calculation Flow

```mermaid
sequenceDiagram
    participant U as User (Terminal UI)
    participant FE as Frontend
    participant API as Express API
    participant Core as Core Library

    U->>FE: Enter package data + "cost"
    FE->>API: POST /api/cost { input }

    alt API available
        API->>API: Zod validation + rate limit
        API->>Core: parseInput(input, 'cost')
        Core-->>API: { baseCost, packages[] }
        loop Each package
            API->>Core: calculatePackageCost(pkg, baseCost)
            Core->>Core: deliveryCost = base + (weight×10) + (distance×5)
            Core->>Core: findBestOffer(weight, distance)
            Core-->>API: { discount, totalCost }
        end
        API-->>FE: { results: [{ id, discount, cost }] }
    else API unavailable (fallback)
        FE->>Core: calculateDeliveryCost(input)
        Core-->>FE: "PKG1 0 175\nPKG2 35 665"
    end

    FE->>Core: parseOutput(output, 'cost', input)
    Core-->>FE: ParsedResult[]
    FE-->>U: Display results table
```

### Delivery Time Calculation Flow

```mermaid
sequenceDiagram
    participant U as User (Terminal UI)
    participant FE as Frontend
    participant API as Express API
    participant Core as Core Library

    U->>FE: Enter packages + vehicles + "time"
    FE->>API: POST /api/delivery/transit { input, transitPackages }

    alt API available
        API->>Core: calculateDeliveryTimeWithTransit(input, transit)
        Core->>Core: parseInput(input, 'time')
        Core->>Core: resolveTransitConflicts()
        Core->>Core: Enrich packages with cost data
        Core->>Core: Sort by weight ↓ then distance ↑

        loop While packages remain
            Core->>Core: Find least-busy vehicle
            Core->>Core: findBestShipment (knapsack ≤20 / greedy >20)
            Core->>Core: deliveryTime = currentTime + distance/speed
            Core->>Core: vehicleReturn = currentTime + 2×(maxDist/speed)
        end

        Core-->>API: DetailedDeliveryResult[]
        API-->>FE: { output, results[], clearedFromTransit, stillInTransit, newTransitPackages, renamedPackages }
    else API unavailable (fallback)
        FE->>Core: calculateDeliveryTimeWithTransit(input, transit)
        Core-->>FE: Same calculation locally
    end

    FE->>Core: parseOutput(output, 'time', input)
    Core-->>FE: ParsedResult[] with time/vehicle/round
    FE-->>U: Display results with delivery times
```

### AWS Staging / Production Architecture

```mermaid
graph TB
    Browser["🌐 Browser"] --> CF["CloudFront CDN<br/>+ Shield Standard"]

    subgraph AWS["AWS Cloud"]
        CF --> WAF_CF["WAF · Rate limit · XSS · Bad inputs"]
        WAF_CF --> S3Route["/* → S3 Origin"]
        WAF_CF --> ApiRoute["/api/* → API Gateway"]

        S3Route --> S3["S3 Bucket"]
        S3 --> React["/react/"]
        S3 --> Vue["/vue/"]
        S3 --> Svelte["/svelte/"]

        ApiRoute --> APIGW["REST API Gateway"]
        APIGW --> WAF_API["WAF · Rate limit · Common rules"]
        WAF_API --> VPCLink["VPC Link"]
        VPCLink --> NLB["NLB (internal)"]
        NLB --> ECS["ECS Fargate<br/>Docker container"]

        ECR["ECR"] -.->|"image"| ECS
        ECS -.->|"logs"| CW["CloudWatch<br/>14-day retention"]
    end
```

**Endpoints** — no custom domain; all use AWS-generated URLs:

| Environment | Frontend | API (direct) | API (via CloudFront) |
|---|---|---|---|
| **Production** | [`d31r5a2wvtwynh.cloudfront.net`](https://d31r5a2wvtwynh.cloudfront.net) | `r7b86qfm3h.execute-api.ap-southeast-1.amazonaws.com/production` | `d31r5a2wvtwynh.cloudfront.net/api/*` |
| **Staging** | [`d28gbmf77bx81u.cloudfront.net`](https://d28gbmf77bx81u.cloudfront.net) | `r7b86qfm3h.execute-api.ap-southeast-1.amazonaws.com/staging` | `d28gbmf77bx81u.cloudfront.net/api/*` |

### API Proxy via CloudFront

The frontend uses relative `/api/*` URLs for API calls. CloudFront proxies these requests to API Gateway, so the same relative URLs work identically in development (Vite proxy) and production (CloudFront proxy):

```mermaid
sequenceDiagram
    participant B as Browser
    participant CF as CloudFront
    participant AG as API Gateway
    participant NLB as NLB
    participant ECS as ECS Fargate

    B->>CF: POST /api/cost
    CF->>AG: Forward (OriginPath: /production)
    AG->>NLB: VPC Link
    NLB->>ECS: TCP :3000
    ECS-->>NLB: JSON response
    NLB-->>AG: Response
    AG-->>CF: Response
    CF-->>B: JSON result
```

Configuration:
- **ApiGatewayDomain** parameter passed to `frontend-stack.yml` during deploy
- **CachingDisabled** policy on `/api/*` — API responses are never cached
- **AllViewerExceptHostHeader** origin request policy — forwards all headers except Host
- If no API Gateway domain is provided, the proxy origin is skipped (conditional via `HasApiGateway`)

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

## Docker

All environments (local, staging, production) use the same multi-stage Dockerfile.

```bash
# Build (from project root containing all repos)
docker build -f courier-service/Dockerfile -t courier-service .

# Run API server
docker run -p 3000:3000 courier-service

# Test API - Cost Calculation
curl -s -X POST http://localhost:3000/api/cost \
  -H 'Content-Type: application/json' \
  -d '{"input": "100 3\nPKG1 5 5 OFR001\nPKG2 15 5 OFR002\nPKG3 10 100 OFR003"}' | jq

# Test API - Delivery Time Calculation
curl -s -X POST http://localhost:3000/api/delivery/transit \
  -H 'Content-Type: application/json' \
  -d '{"input": "100 5\nPKG1 50 30 OFR001\nPKG2 75 125 NA\nPKG3 175 100 OFR003\nPKG4 110 60 OFR002\nPKG5 155 95 NA\n2 70 200", "transitPackages": []}' | jq

# Run CLI interactively
docker run -it --entrypoint node courier-service courier-service-cli/bin/courier-service

# Run CLI in local-only mode (no API dependency)
docker run -it --entrypoint node courier-service courier-service-cli/bin/courier-service --local
```

> **Note:** The CLI runs as an interactive terminal UI (Ink TUI). Use `-it` flags for Docker to enable TTY interaction. For non-interactive/scripted usage, use the API endpoints directly.

### Docker Compose

```bash
docker compose up courier-api              # Start API server on port 3000
docker compose run -it courier-service     # Run CLI interactively
```

### Docker Image Details

| Stage | Base | Purpose |
|-------|------|---------|
| Build | `node:20-alpine` | Install deps, compile TypeScript for core, CLI, and API |
| Runtime | `node:20-alpine` | Production deps only + compiled JS. ~60MB image |

The runtime image includes:
- `EXPOSE 3000` — API port
- `HEALTHCHECK` — `wget` to `/api/health` every 30s
- `CMD` — defaults to running the API server
- `NODE_ENV=production`
- Graceful shutdown on `SIGTERM`/`SIGINT` — closes connections cleanly before ECS task stops

## AWS Deployment

### Prerequisites

1. **AWS CLI** installed and configured (`aws configure`)
2. **Docker** running locally (for building/pushing images)
3. **GitHub Secrets** set on the `courier-service` repo:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`

### Step 1: Deploy Infrastructure

Creates all AWS resources (S3, CloudFront, VPC, ECS, NLB, REST API Gateway, WAF):

```bash
cd courier-service
./scripts/deploy-infra.sh production
```

This deploys two CloudFormation stacks:
- `courier-frontend-production` — S3 + CloudFront + WAF + API proxy origin
- `courier-api-production` — ECR + VPC + ECS Fargate + NLB + REST API Gateway + WAF

### Step 2: Deploy API

Builds the Docker image, pushes to ECR, and updates the ECS service:

```bash
./scripts/deploy-api.sh production
```

### Step 3: Deploy Frontend

Builds all 3 frameworks (React, Vue, Svelte) and uploads to S3:

```bash
./scripts/deploy-frontend.sh production
```

### Frontend Framework Switching

All three frameworks (React, Vue, Svelte) are deployed simultaneously to S3 and served via CloudFront:

```
https://d31r5a2wvtwynh.cloudfront.net/react/   ← React build
https://d31r5a2wvtwynh.cloudfront.net/vue/     ← Vue build
https://d31r5a2wvtwynh.cloudfront.net/svelte/  ← Svelte build
```

A **CloudFront Function** handles SPA routing — rewriting non-asset paths (e.g. `/react/some-path`) to the framework's `index.html`. The root URL (`/`) redirects to the default framework (configured via `DefaultFramework` parameter).

**Framework switching is per-user**: each user types `use vue` or `use svelte` in their terminal UI, which navigates their browser to `/<framework>/`. Other users are unaffected.

### CI/CD Deployment

**Production** (this branch) — manual only via `workflow_dispatch`:

```bash
gh workflow run deploy-production.yml --ref main -f deploy_target=all
```

This deploys to separate CloudFormation stacks (`courier-frontend-production`, `courier-api-production`) on the same AWS account as staging. All sub-repos are checked out from their `main` branch.

1. Runs all tests (core, CLI, API, frontend)
2. Deploys/updates CloudFormation stacks
3. Builds and pushes Docker image to ECR
4. Updates ECS Fargate service
5. Builds all 3 frontend frameworks (with `--base=/<framework>/`) and uploads to S3
6. Invalidates CloudFront cache

**Staging** — lives on the `staging` branch. Sub-repo CI auto-triggers staging deploys (from sub-repo `main` branches) via `gh workflow run`. Once staging is verified, merge `staging` → `main` and deploy production manually. See the staging branch README for details.

### AWS Services Used

| Service | Purpose | Cost |
|---------|---------|------|
| **S3** | Frontend static hosting (React/Vue/Svelte builds) | Free tier: 5GB |
| **CloudFront** | CDN + HTTPS for frontend | Free tier: 1TB/mo |
| **API Gateway** | REST API proxy to ECS via VPC Link + NLB | Free tier: 1M calls/mo |
| **ECS Fargate** | Serverless Docker container for API | ~$0.04/hr (0.25 vCPU) |
| **ECR** | Docker image registry | Free tier: 500MB |
| **NLB** | Network load balancer for ECS tasks (internal) | Free tier: 750 hrs/mo |
| **WAF** | Rate limiting + managed rules (XSS, bad inputs) | ~$5/mo per WebACL |
| **Shield Standard** | DDoS protection on CloudFront | Free |
| **CloudWatch Logs** | Container logs (14-day retention) | Free tier: 5GB |

### Infrastructure Files

```
infra/
  cloudformation/
    frontend-stack.yml   # S3 + CloudFront + CloudFront Function (SPA routing) + API proxy origin + WAF
    api-stack.yml        # ECR + VPC + ECS Fargate + NLB + REST API Gateway + WAF (REGIONAL)
  env/
    production.env       # Production config (region, stack names, default framework)
scripts/
  deploy-infra.sh        # Deploy/update CloudFormation stacks
  deploy-api.sh          # Build Docker → push ECR → update ECS
  deploy-frontend.sh     # Build all frameworks (--base=/<fw>/) → S3 → invalidate CloudFront
  switch-framework.sh    # Legacy: switch framework via CloudFront origin path
```

## CI/CD

GitHub Actions workflow (`.github/workflows/ci.yml`) runs on push/PR:

1. **test-core** — installs and tests `courier-service-core` (Node 18 + 20, 147 tests)
2. **test-cli** — installs core + CLI, runs CLI tests (Node 18 + 20, 113 tests)
3. **test-api** — installs core + API, runs API tests (Node 18 + 20, 33 tests)
4. **test-frontend** — type-checks, tests, and builds the frontend (Node 20, 248 tests)
5. **test-system** — verifies core library outputs and API cost endpoint

Production deployment (`.github/workflows/deploy-production.yml`) — manual `workflow_dispatch` only:

```bash
gh workflow run deploy-production.yml --ref main -f deploy_target=all
```

### Deployment Flow

```mermaid
graph LR
    Push["Push to sub-repo<br/>main branch"] --> CI["Sub-repo CI<br/>tests pass"]
    CI -->|"auto-trigger"| Staging["Deploy Staging<br/>(staging branch)"]
    Staging --> Test["Test on staging"]
    Test -->|"manual dispatch"| Prod["Deploy Production<br/>(main branch)"]
```

## Security

### Express Middleware (Application Layer)

| Layer | Protection |
|-------|-----------|
| **Helmet** | Security headers against XSS, clickjacking, MIME sniffing |
| **CORS** | Origin whitelist (localhost dev + CloudFront distributions) |
| **Rate Limiting** | Global: 100 req/15min, Calculations: 30 req/min |
| **Zod Validation** | Schema-based input validation (type safety, length limits, all errors returned) |
| **Body Size Limit** | 100kb max request body |
| **Morgan** | HTTP request logging |

### AWS Infrastructure (Network Layer)

| Layer | Protection |
|-------|-----------|
| **AWS WAF** | Rate limiting (1000-2000 req/5min per IP), managed rule sets |
| **AWS Shield Standard** | Automatic DDoS protection (free on CloudFront) |
| **CloudFront** | HTTPS-only, TLS 1.2+, HTTP/2+3 |
| **REST API Gateway** | Request throttling, payload size limits, WAF integration |
| **VPC** | Network isolation for ECS tasks, security groups |
| **NLB** | Internal load balancer, no public exposure |
| **ECR Image Scanning** | Vulnerability scanning on push |
| **S3 OAC** | Bucket accessible only via CloudFront (no direct S3 URL) |

## Shared Dependency Model

All three consumer packages depend on `@nurulizyansyaza/courier-service-core` via `file:../courier-service-core`:

```
courier-service-core (source of truth)
  ├── courier-service-api    → direct import, no fallback needed
  ├── courier-service-cli    → API-first + local core fallback
  └── courier-service-frontend → API-first + local core fallback
```

- **Zero logic duplication** — parsing, cost calculation, delivery planning, transit conflict resolution, and offer validation all live in core
- **Centralized constants** — magic numbers (weight/distance multipliers, package limits) and shared regex patterns defined once in `constants.ts`
- **API-first with fallback** — CLI and frontend try the API first; if unreachable, run the same core functions locally
- When core is updated, all consumers get the changes after `npm ci` / rebuild
- CI builds core first, then runs downstream tests to catch breaking changes

## Related Repos

- [courier-service-core](https://github.com/nurulizyansyaza/courier-service-core) — Core logic NPM package (147 tests)
- [courier-service-cli](https://github.com/nurulizyansyaza/courier-service-cli) — CLI application with Ink TUI (113 tests)
- [courier-service-api](https://github.com/nurulizyansyaza/courier-service-api) — Express REST API with Bruno test collection (33 tests)
- [courier-service-frontend](https://github.com/nurulizyansyaza/courier-service-frontend) — React/Vue/Svelte dashboard (248 tests)
