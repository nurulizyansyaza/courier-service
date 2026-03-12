# Courier Service

Orchestration repo for the **Courier Service** coding challenge (Everest Engineering). Ties together the core library and CLI app with CI/CD and Docker.

## Architecture

```
courier-service/          ← this repo (CI/CD + Docker)
courier-service-core/     ← NPM package: cost, offers, shipment planning
courier-service-cli/      ← CLI app consuming the core package
```

## CI/CD

GitHub Actions workflow (`.github/workflows/ci.yml`) runs on push/PR:

1. **test-core** — installs and tests `courier-service-core` (Node 18 + 20)
2. **test-cli** — installs core + CLI, runs CLI tests (Node 18 + 20)
3. **e2e** — verifies Problem 1 and Problem 2 outputs match expected values

## Docker

```bash
# Build (from project root containing all 3 repos)
docker build -t courier-service .

# Run Problem 1
printf '100 3\nPKG1 5 5 OFR001\nPKG2 15 5 OFR002\nPKG3 10 100 OFR003\n' | docker run -i courier-service cost

# Run Problem 2
printf '100 5\nPKG1 50 30 OFR001\nPKG2 75 125 OFR008\nPKG3 175 100 OFR003\nPKG4 110 60 OFR002\nPKG5 155 95 NA\n2 70 200\n' | docker run -i courier-service delivery
```

## Related Repos

- [courier-service-core](https://github.com/nurulizyansyaza/courier-service-core) — Core logic NPM package
- [courier-service-cli](https://github.com/nurulizyansyaza/courier-service-cli) — CLI application
