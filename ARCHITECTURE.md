# Courier Service

Orchestration repo for the **Courier Service** App Calculator. Ties together the core library, CLI app, Express API and frontend dashboard with CI/CD, Docker and homelab deployment.

## Architecture

```
courier-service/          ← this repo (CI/CD + Docker + Homelab infra)
courier-service-core/     ← NPM package: cost, offers, shipment planning (147 tests)
courier-service-cli/      ← Interactive CLI with Ink TUI (124 tests)
courier-service-api/      ← Express REST API with security middleware (33 tests)
courier-service-frontend/ ← React/Vue/Svelte dashboard with API integration (257 tests)
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
- **CLI theme**: Forces a dark terminal background and uses a fixed dark color palette, ensuring consistent rendering regardless of the user's terminal theme (local, Docker, SSH). Background is restored to default on exit.
- **Multi-line input**: Both CLI and frontend support Shift+Enter for new lines. Smart Enter auto-adds a new line when the header declares more packages than currently entered. The frontend's `❯` prompt tracks the cursor line within multi-line input. Arrow keys navigate between lines mid-input and only trigger history navigation on the first/last line.

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

### Homelab Production Architecture

```mermaid
graph TB
    Browser["🌐 Browser"] --> HostNginx["Host Nginx<br/>nurulizyansyaza.com"]

    subgraph Homelab["Homelab Server"]
        HostNginx --> RateLimit["Rate Limiting<br/>200 req/min global · 60 req/min API"]

        RateLimit --> Landing["/courier-service/ → Landing Page"]
        RateLimit --> ApiRoute["/api/* → API Proxy"]
        RateLimit --> FERoute["/frontend/* → Static Files"]
        RateLimit --> CLIRoute["/cli → CLI Docs"]

        FERoute --> FrontendFiles["Frontend Builds (disk)"]
        FrontendFiles --> React["/react/"]
        FrontendFiles --> Vue["/vue/"]
        FrontendFiles --> Svelte["/svelte/"]

        ApiRoute --> API["Docker: courier-api<br/>Express on :3000"]
        RateLimit --> StagingAPI["/api/* (staging)"]
        StagingAPI --> APIStaging["Docker: courier-api-staging<br/>Express on :3001"]

        API -.->|"logs"| Logs["Docker Logs<br/>json-file driver"]
    end
```

**Endpoints** — served from homelab at `nurulizyansyaza.com`:

| Environment | Landing Page | Frontend | API | Health Check |
|---|---|---|---|---|
| **Production** | `courier-service.nurulizyansyaza.com/` | `/react/` | `/api/*` | `/api/health` |
| **Staging** | `staging-courier-service.nurulizyansyaza.com/` | `/react/` | `/api/*` | `/api/health` |

### API Proxy via Nginx

The frontend uses `/api/*` URLs for API calls. The host Nginx proxies to the Docker API container:

```mermaid
sequenceDiagram
    participant B as Browser
    participant N as Host Nginx
    participant API as Docker: courier-api

    B->>N: POST /api/cost
    N->>API: proxy_pass http://127.0.0.1:3000/api/cost
    API-->>N: JSON response
    N-->>B: JSON result
```

Configuration:
- **Host Nginx reverse proxy** to Docker containers (prod :3000, staging :3001)
- **Nginx is not containerized** — it runs on the host, serving the personal site and project routes
- **No caching** on `/api/*` — API responses are never cached
- **Rate limiting** — 60 req/min on API routes, 200 req/min global
- If API container is unhealthy, Nginx returns 502
