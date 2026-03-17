# Courier Service — Getting Started

> **Coding Challenge**: Courier Service — Delivery Cost & Time Estimation
> **Role**: Full Stack Engineer @ [EverestEngineering](https://www.linkedin.com/company/everestengineering/) (PJ, Malaysia)
> **Candidate**: Nurul Izyan Syaza

---

## What This Project Does

A courier service calculator that solves two problems:

1. **Problem 1 — Delivery Cost**: Calculate delivery cost for each package with discount offers
2. **Problem 2 — Delivery Time**: Calculate estimated delivery time by assigning packages to vehicles, maximising packages per trip

**The solution**: Built as a full stack application with a shared core library, REST API, interactive CLI and a multi-framework frontend dashboard.

---

## Tech Stack (with further details linked below)

### Core [courier-service-core](https://github.com/nurulizyansyaza/courier-service-core)

| Technology | Version | Purpose |
|---|---|---|
| **Node.js** | 20+ | Runtime |
| **TypeScript** | 5.7 | Type safe code across all repos |
| **Jest** | 29 | Unit testing (core, API, CLI) |

### API [courier-service-api](https://github.com/nurulizyansyaza/courier-service-api)

| Technology | Version | Purpose |
|---|---|---|
| **Express** | 4.21 | HTTP server |
| **Zod** | 4.3 | Input validation (schema-based) |
| **Helmet** | 8.1 | Security headers |
| **CORS** | 2.8 | Cross origin requests |
| **express-rate-limit** | 8.3 | Rate limiting |
| **Morgan** | 1.10 | HTTP request logging |
| **Supertest** | 7.0 | API integration testing |

### CLI [courier-service-cli](https://github.com/nurulizyansyaza/courier-service-cli)

| Technology | Version | Purpose |
|---|---|---|
| **Ink** | 3.2 | Terminal UI framework (React for CLIs) |
| **React** | 17 | Component rendering for Ink |
| **Commander** | 12.1 | Command line argument parsing |

### Frontend [courier-service-frontend](https://github.com/nurulizyansyaza/courier-service-frontend)

| Technology | Version | Purpose |
|---|---|---|
| **React** | 18.3 | Multi Framework option 1 |
| **Vue** | 3.5 | Multi Framework option 2 |
| **Svelte** | 5.34 | Multi Framework option 3 |
| **Vite** | 6.3 | Build tool & dev server |
| **Tailwind CSS** | 4.1 | Styling |
| **Vitest** | 4.1 | Unit testing |
| **Lucide** | 0.487 | Icons |

### Infrastructure & DevOps

| Technology | Purpose |
|---|---|
| **Docker** | Containerisation (multi stage build) |
| **GitHub Actions** | CI/CD pipelines |
| **AWS CloudFormation** | Infrastructure as Code |
| **AWS S3** | Frontend static hosting |
| **AWS CloudFront** | CDN + HTTPS |
| **AWS ECS Fargate** | Serverless container hosting for API |
| **AWS ECR** | Docker image registry |
| **AWS API Gateway** | REST API proxy with VPC Link |
| **AWS WAF** | Web Application Firewall |
| **AWS NLB** | Internal load balancer |

### Testing

| Repo | Framework | Tests |
|---|---|---|
| Core | Jest | 147 |
| API | Jest | 33 |
| CLI | Jest | 113 |
| Frontend | Vitest | 248 |
| **Total** | | **541** |

---

## Tools & How They Were Used

### Planning & Design

| Tool | Used For |
|---|---|
| **Pen & Paper** | Understanding problems, scratch planning: logic ideas, project structures & system architecture design, infrastructure, UI rough sketches |
| **Mermaid** | Diagrams: Infrastructure, System Architecture, Sequence, Flowcharts |
| **Bruno** | API testing and collections |
| **Figma** | UI design |
| **Google** | Research on tech stacks commonly used by Everest Engineering. Research on AWS services for project infrastructure |

### AI Tools (with nature of assistance received)

| Tool | Used For |
|---|---|
| **GitHub Copilot** (with sub-agents) | Debugging, syntax, refactoring, GitHub Actions issues, PR reviews and documentation |
| **Copilot CLI** (with sub-agents) | Debugging, syntax, refactoring, GitHub Actions issues, PR reviews and documentation |

---

## Project Setup

### Prerequisites

- **Node.js** 18 or 20 (recommended: 20)
- **npm** (comes with Node.js)
- **Git**
- **Docker** (optional — for one command dev setup)

### Step 1 — Clone all repos

```bash
mkdir courier-service-project && cd courier-service-project

git clone https://github.com/nurulizyansyaza/courier-service.git
git clone https://github.com/nurulizyansyaza/courier-service-core.git
git clone https://github.com/nurulizyansyaza/courier-service-cli.git
git clone https://github.com/nurulizyansyaza/courier-service-api.git
git clone https://github.com/nurulizyansyaza/courier-service-frontend.git
```

### Step 2 — Install and build

```bash
# Build the core library first (other repos depend on it)
cd courier-service-core && npm ci && npm run build && cd ..

# Install the rest
cd courier-service-api && npm ci && npm run build && cd ..
cd courier-service-cli && npm ci && cd ..
cd courier-service-frontend && npm ci && cd ..
```

### Alternative — Docker Dev Setup

If you have **Docker** installed, you can skip the manual setup and run everything with one command:

```bash
cd courier-service
docker compose -f docker-compose.dev.yml up
```

This starts:
- **Core** — watches for changes and rebuilds automatically
- **API** — Express server on `http://localhost:3000` (auto-restarts on change)
- **Frontend** — Vite dev server on `http://localhost:5173` (hot module replacement)

**Run the CLI:**

```bash
docker compose -f docker-compose.dev.yml run --rm cli
```

**Run all 541 tests:**

```bash
docker compose -f docker-compose.dev.yml run --rm test
```

**Run tests for a specific repo:**

```bash
docker compose -f docker-compose.dev.yml run --rm test-core
docker compose -f docker-compose.dev.yml run --rm test-api
docker compose -f docker-compose.dev.yml run --rm test-cli
docker compose -f docker-compose.dev.yml run --rm test-fe
```

**Port conflicts?** Ports are configurable:

```bash
API_PORT=3001 FE_PORT=5174 docker compose -f docker-compose.dev.yml up
```

**Stop everything:**

```bash
docker compose -f docker-compose.dev.yml down
```

> **Note:** Source files are mounted as volumes — edit code locally and changes are picked up automatically inside Docker (hot-reload).

---

## How to Run Tests

```bash
# Run all tests repo by repo
cd courier-service-core && npm test && cd ..       # 147 tests
cd courier-service-api && npm test && cd ..        # 33 tests
cd courier-service-cli && npm test && cd ..        # 113 tests
cd courier-service-frontend && npm test && cd ..   # 248 tests
```

All tests should pass. Total: **541 tests**.

---

## How to Run the App

### Run the API

```bash
cd courier-service-api
npm run dev
```

The API starts on `http://localhost:3000`. You can test it with:

```bash
# Health check
curl http://localhost:3000/api/health
```

### Run the CLI

```bash
cd courier-service-cli
npm start
```

This opens an interactive terminal UI. Type your input line by line, then press Enter to calculate.

You can also paste multi line input directly, it will be processed as separate lines.

### Run the Frontend

```bash
# Start the API first (in one terminal)
cd courier-service-api && npm run dev

# Then start the frontend (in another terminal)
cd courier-service-frontend && npm run dev
```

The frontend opens on `http://localhost:5173`. It connects to the API automatically.

> **Note:** The frontend works without the API too — it falls back to running calculations locally using the core library.

---

## Example Test Data

### Problem 1 — Delivery Cost

**Input:**

```
100 3
PKG1 5 5 OFR001
PKG2 15 5 OFR002
PKG3 10 100 OFR003
```

**What it means:**
- `100 3` → base delivery cost is 100, there are 3 packages
- `PKG1 5 5 OFR001` → Package PKG1, weighs 5kg, distance 5km, using offer code OFR001

**Expected output:**

```
PKG1 0 175
PKG2 0 275
PKG3 35 665
```

**Format:** `package_id discount total_cost`

**API request:**

```bash
curl -s -X POST http://localhost:3000/api/cost \
  -H 'Content-Type: application/json' \
  -d '{"input": "100 3\nPKG1 5 5 OFR001\nPKG2 15 5 OFR002\nPKG3 10 100 OFR003"}'
```

### Problem 2 — Delivery Time

**Input:**

```
100 5
PKG1 50 30 OFR001
PKG2 75 125 NA
PKG3 175 100 OFR003
PKG4 110 60 OFR002
PKG5 155 95 NA
2 70 200
```

**What it means:**
- `100 5` → base delivery cost is 100, there are 5 packages
- Each package line → `id weight distance offer_code` (use `NA` for no offer)
- `2 70 200` → 2 vehicles, max speed 70 km/hr, max carriable weight 200 kg

**Expected output:**

```
PKG4 105 1395 0.85
PKG2 0 1475 1.78
PKG3 0 2350 1.42
PKG5 0 2125 4.21
PKG1 0 750 4.00
```

**Format:** `package_id discount total_cost estimated_delivery_time_in_hours`

**API request:**

```bash
curl -s -X POST http://localhost:3000/api/delivery/transit \
  -H 'Content-Type: application/json' \
  -d '{
    "input": "100 5\nPKG1 50 30 OFR001\nPKG2 75 125 NA\nPKG3 175 100 OFR003\nPKG4 110 60 OFR002\nPKG5 155 95 NA\n2 70 200",
    "transitPackages": []
  }'
```

### Available Offer Codes

| Code | Discount | Distance (km) | Weight (kg) |
|---|---|---|---|
| OFR001 | 10% | < 200 | 70 – 200 |
| OFR002 | 7% | 50 – 150 | 100 – 250 |
| OFR003 | 5% | 50 – 250 | 10 – 150 |

Use `NA` (case-insensitive) when no offer code applies.

---

## Assumptions & Tradeoffs

### Assumptions

- **Package IDs must be sequential** — `PKG1`, `PKG2`, `PKG3`, etc. (case-insensitive). The system validates this and rejects non-sequential IDs.
- **Offer codes are strictly validated** — only `OFR001`, `OFR002`, `OFR003`, and `NA` are accepted. Invalid codes like `OFR008` are rejected with a clear error message.
- **Delivery time is rounded to 2 decimal places** as specified in the problem statement.
- **All vehicles travel at the same speed** and return to the source station after each delivery.
- **Output order for delivery time** follows delivery round order (packages delivered first appear first), not input order.

### Tradeoffs

- **Multi-repo over monorepo** — chose separate repos for core, API, CLI and frontend to keep each concern isolated and independently deployable. Tradeoff: slightly more complex setup (clone 5 repos) but each repo has its own CI/CD, versioning and clear boundaries.
- **Interactive CLI over piped stdin** — the CLI uses Ink (React for terminals) for a rich interactive experience with arrow keys, history, paste support and real time validation. Tradeoff: can't pipe input via `echo "..." | cli` but the API serves the non-interactive use case.
- **API-first with local fallback** — both CLI and frontend try the API first, then fall back to the core library if the API is unreachable. This gives the best of both worlds: security middleware (rate limiting, validation) when available and offline capability when not.
- **Three frontend frameworks** — React, Vue and Svelte share the same core logic. Users can switch frameworks at runtime. This demonstrates framework-agnostic architecture while adding some build complexity.

### What I'd Do Next With More Time

- **Add end-to-end tests** — Playwright or Cypress tests for the frontend, covering the full flow from input to results display.
- **Add WebSocket support** — real time delivery tracking updates instead of polling.
- **Custom domain** — set up Route 53 with a custom domain instead of CloudFront generated URLs.
- **Add monitoring** — CloudWatch dashboards, alerts and X-Ray tracing for API performance visibility.
- **Database persistence** — store calculation history and user sessions in DynamoDB instead of browser storage.
- **Offer management API** — CRUD endpoints for managing offer codes dynamically instead of hardcoded values.
- **User authentication** — add JWT based auth for the API and a login flow in the frontend for a more complete full stack experience.
- **Role-based access control** — implement different access levels for users, restricting certain actions based on roles.

---

## Live Links

### Production

| Resource | URL |
|---|---|
| **GitHub** (with instructions) | [github.com/nurulizyansyaza/courier-service/tree/main](https://github.com/nurulizyansyaza/courier-service/tree/main) |
| **Frontend** | [d31r5a2wvtwynh.cloudfront.net](https://d31r5a2wvtwynh.cloudfront.net/) |
| **API** (direct) | [r7b86qfm3h.execute-api.ap-southeast-1.amazonaws.com/production](https://r7b86qfm3h.execute-api.ap-southeast-1.amazonaws.com/production) |
| **API** (via CloudFront) | `d31r5a2wvtwynh.cloudfront.net/api/*` |

### Staging

| Resource | URL |
|---|---|
| **GitHub** (with instructions) | [github.com/nurulizyansyaza/courier-service/tree/staging](https://github.com/nurulizyansyaza/courier-service/tree/staging) |
| **Frontend** | [d28gbmf77bx81u.cloudfront.net](https://d28gbmf77bx81u.cloudfront.net) |
| **API** (direct) | [r7b86qfm3h.execute-api.ap-southeast-1.amazonaws.com/staging](https://r7b86qfm3h.execute-api.ap-southeast-1.amazonaws.com/staging) |
| **API** (via CloudFront) | `d28gbmf77bx81u.cloudfront.net/api/*` |

### Project Board

[github.com/users/nurulizyansyaza/projects/2](https://github.com/users/nurulizyansyaza/projects/2)

---

## Related Repos

| Repo | Description | Tests |
|---|---|---|
| [courier-service](https://github.com/nurulizyansyaza/courier-service) | Orchestration — CI/CD, Docker, AWS infra | — |
| [courier-service-core](https://github.com/nurulizyansyaza/courier-service-core) | Core logic — cost calculation, delivery planning, offers | 147 |
| [courier-service-api](https://github.com/nurulizyansyaza/courier-service-api) | Express REST API with security middleware | 33 |
| [courier-service-cli](https://github.com/nurulizyansyaza/courier-service-cli) | Interactive CLI with Ink TUI | 113 |
| [courier-service-frontend](https://github.com/nurulizyansyaza/courier-service-frontend) | React / Vue / Svelte dashboard | 248 |
