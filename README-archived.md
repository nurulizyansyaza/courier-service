# Courier Service — Getting Started

## What This Project Does

A courier service calculator that solves two problems:

1. **Problem 1 — Delivery Cost**: Calculate delivery cost for each package with discount offers
2. **Problem 2 — Delivery Time**: Calculate estimated delivery time by assigning packages to vehicles, maximising packages per trip

**The solution**: Built as a full stack application with a shared core library, REST API, interactive CLI and a multi-framework frontend dashboard.

---

## Tech Stack, Infrastructure & Architecture (with further details linked below)

### Infrastructure & Architecture
- **Link**: [ARCHITECTURE.md](https://github.com/nurulizyansyaza/courier-service/blob/main/ARCHITECTURE.md)

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
| **Chalk** | 5 | Dark terminal color palette |

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
| CLI | Jest | 124 |
| Frontend | Vitest | 257 |
| **Total** | | **561** |

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

Before you start, make sure you have these installed on your machine:

| Tool | Version | How to check | How to install |
|---|---|---|---|
| **Node.js** | 18 or 20 (recommended: 20) | `node --version` | [nodejs.org](https://nodejs.org/) |
| **npm** | Comes with Node.js | `npm --version` | Installed with Node.js |
| **Git** | Any recent version | `git --version` | [git-scm.com](https://git-scm.com/) |
| **Docker** | Any recent version (optional) | `docker --version` | [docker.com](https://www.docker.com/products/docker-desktop/) |

> **Tip:** If you see a version number when running the check commands above, you're good to go.

---

### Option A — Manual Setup (step by step)

#### Step 1 — Create a project folder

Open your terminal and create a folder to hold all the repos:

```bash
mkdir courier-service-project
cd courier-service-project
```

#### Step 2 — Clone all repos

Clone each repo one by one into the project folder:

```bash
git clone https://github.com/nurulizyansyaza/courier-service.git
git clone https://github.com/nurulizyansyaza/courier-service-core.git
git clone https://github.com/nurulizyansyaza/courier-service-api.git
git clone https://github.com/nurulizyansyaza/courier-service-cli.git
git clone https://github.com/nurulizyansyaza/courier-service-frontend.git
```

After this step, your folder should look like:

```
courier-service-project/
├── courier-service/           ← main repo (CI/CD, Docker, infra)
├── courier-service-core/      ← shared core library
├── courier-service-api/       ← REST API
├── courier-service-cli/       ← interactive CLI
└── courier-service-frontend/  ← web dashboard
```

#### Step 3 — Build the core library first

The core library must be built **before** anything else — all other repos depend on it.

```bash
cd courier-service-core
npm ci
npm run build
```

You should see a `dist/` folder created. Then go back to the project root:

```bash
cd ..
```

#### Step 4 — Install and build the API

```bash
cd courier-service-api
npm ci
npm run build
cd ..
```

#### Step 5 — Install the CLI

```bash
cd courier-service-cli
npm ci
cd ..
```

#### Step 6 — Install the frontend

```bash
cd courier-service-frontend
npm ci
cd ..
```

**Done!** Everything is installed. You can now run the app (see [How to Run the App](#how-to-run-the-app) below).

---

### Option B — Docker Dev Setup (one command)

If you have Docker installed, you can skip all the manual steps above:

#### Step 1 — Clone all repos

Same as Option A Steps 1 and 2 above.

#### Step 2 — Start everything

```bash
cd courier-service
docker compose -f docker-compose.dev.yml up
```

Wait for the output to show all services are running. This starts:

- **Core** — watches for changes and rebuilds automatically
- **API** — Express server on `http://localhost:3000`
- **Frontend** — Vite dev server on `http://localhost:5173` (hot module replacement)

#### Run the CLI in Docker

Open a new terminal window:

```bash
cd courier-service
docker compose -f docker-compose.dev.yml run --rm cli
```

#### Run all tests in Docker

```bash
cd courier-service
docker compose -f docker-compose.dev.yml run --rm test
```

#### Run tests for a specific repo

```bash
docker compose -f docker-compose.dev.yml run --rm test-core
docker compose -f docker-compose.dev.yml run --rm test-api
docker compose -f docker-compose.dev.yml run --rm test-cli
docker compose -f docker-compose.dev.yml run --rm test-fe
```

#### Port already in use?

If you see an error like `port is already in use`, change the port:

```bash
API_PORT=3001 FE_PORT=5174 docker compose -f docker-compose.dev.yml up
```

> **Note:** Since you used `FE_PORT=5174`, visit http://localhost:5174 instead.

#### To kill whatever's on 5173:

```bash
lsof -i :5173   # find the PID
kill <PID>       # then you can use the default port
```

#### Stop everything

```bash
docker compose -f docker-compose.dev.yml down
```

> **Note:** Source files are mounted as volumes — edit code on your machine and changes are picked up automatically inside Docker (hot-reload).

---

## How to Run Tests

Make sure you're in the project root (`courier-service-project/`).

```bash
# Core — 147 tests
cd courier-service-core && npm test && cd ..

# API — 33 tests
cd courier-service-api && npm test && cd ..

# CLI — 124 tests
cd courier-service-cli && npm test && cd ..

# Frontend — 257 tests
cd courier-service-frontend && npm test && cd ..
```

All tests should pass. Total: **561 tests**.

---

## How to Run the App

### Run the API

Open a terminal and run:

```bash
cd courier-service-api
npm run dev
```

You should see output like `Server listening on port 3000`. The API is now running at `http://localhost:3000`.

To check if it's working, open a **new terminal** and run:

```bash
curl http://localhost:3000/api/health
```

You should see `{"status":"ok"}`.

### Run the CLI

Open a terminal and run:

```bash
cd courier-service-cli
npm start
```

This opens an interactive terminal UI. Type your input line by line, then press Enter to calculate.

You can also paste multi-line input directly — it will be processed as separate lines. Use **Shift+Enter** to add new lines manually. Smart Enter automatically inserts a new line when more package lines are expected based on the header count.

The CLI forces a dark background on the terminal and uses a fixed dark color palette, ensuring consistent rendering regardless of the user's terminal theme.

> **Tip:** The CLI works without the API running. It will automatically fall back to local calculations using the core library.

### Run the Frontend

You need **two terminals** for this:

**Terminal 1** — Start the API first:

```bash
cd courier-service-api
npm run dev
```

**Terminal 2** — Then start the frontend:

```bash
cd courier-service-frontend
npm run dev
```

Open your browser and go to `http://localhost:5173`.

> **Note:** The frontend also works without the API — it falls back to running calculations locally using the core library.

---

## API Testing with Bruno

The API includes a [Bruno](https://www.usebruno.com/) collection for testing all endpoints interactively. The collection is located at [`courier-service-api/bruno/`](https://github.com/nurulizyansyaza/courier-service-api/tree/main/bruno).

### Setup Bruno

1. **Download and install Bruno** from [usebruno.com/downloads](https://www.usebruno.com/downloads) (or run `brew install bruno` on macOS)
2. **Open Bruno** and click **Open Collection**
3. **Navigate to** the `courier-service-api/bruno/` folder and select it
4. **Select an environment** — click the environment dropdown (top right corner) and choose **Local**

### Environments

| Environment | Base URL | When to use |
|---|---|---|
| **Local** | `http://localhost:3000` | When running the API locally with `npm run dev` |
| **Staging** | `https://d28gbmf77bx81u.cloudfront.net` | Test against the staging deployment |
| **Production** | `https://d31r5a2wvtwynh.cloudfront.net` | Test against the production deployment |

### How to use

- **Run a single request** — click any request in the sidebar, then click **Send** (or press <kbd>Ctrl</kbd>+<kbd>Enter</kbd>)
- **Run all requests in a folder** — right-click a folder (e.g. `cost`) and select **Run All Requests**
- **Switch environment** — use the dropdown at the top right to test against Local, Staging or Production

### What's included

The collection covers all endpoints with **37 requests** including happy paths, edge cases and validation errors:

| Folder | Requests | What it tests |
|---|---|---|
| `health/` | 1 | Health check endpoint |
| `cost/` | 6 | Cost calculation + validation errors |
| `cost-validation/` | 16 | Detailed input validation (IDs, weights, offers, multi-error) |
| `delivery/` | 3 | Delivery time calculation + validation |
| `delivery-validation/` | 4 | Vehicle line validation, multi-error |
| `delivery-transit/` | 4 | Transit package merging, ID conflicts |

Each request includes inline assertions and documentation explaining the expected behavior.

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
| [courier-service-cli](https://github.com/nurulizyansyaza/courier-service-cli) | Interactive CLI with Ink TUI | 124 |
| [courier-service-frontend](https://github.com/nurulizyansyaza/courier-service-frontend) | React / Vue / Svelte dashboard | 257 |
