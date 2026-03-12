# Stage 1: Build
FROM node:20-alpine AS build
WORKDIR /app

COPY courier-service-core/ ./courier-service-core/
RUN cd courier-service-core && npm ci && npm run build

COPY courier-service-cli/ ./courier-service-cli/
RUN cd courier-service-cli && npm ci && npx tsc

# Stage 2: Runtime
FROM node:20-alpine
WORKDIR /app

COPY --from=build /app/courier-service-core/dist/ ./courier-service-core/dist/
COPY --from=build /app/courier-service-core/package.json ./courier-service-core/

COPY --from=build /app/courier-service-cli/dist/ ./courier-service-cli/dist/
COPY --from=build /app/courier-service-cli/bin/ ./courier-service-cli/bin/
COPY --from=build /app/courier-service-cli/package.json ./courier-service-cli/
COPY --from=build /app/courier-service-cli/package-lock.json ./courier-service-cli/
RUN cd courier-service-cli && npm ci --omit=dev

ENTRYPOINT ["node", "courier-service-cli/bin/courier-service"]
