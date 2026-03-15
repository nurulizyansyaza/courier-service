# Stage 1: Build
FROM node:20-alpine AS build
WORKDIR /app

COPY courier-service-core/package*.json ./courier-service-core/
RUN cd courier-service-core && npm ci
COPY courier-service-core/ ./courier-service-core/
RUN cd courier-service-core && npm run build

COPY courier-service-cli/package*.json ./courier-service-cli/
RUN cd courier-service-cli && npm ci
COPY courier-service-cli/ ./courier-service-cli/
RUN cd courier-service-cli && npx tsc

COPY courier-service-api/package*.json ./courier-service-api/
RUN cd courier-service-api && npm ci
COPY courier-service-api/ ./courier-service-api/
RUN cd courier-service-api && npm run build

# Stage 2: Runtime
FROM node:20-alpine
WORKDIR /app

RUN apk add --no-cache wget

COPY --from=build /app/courier-service-core/package.json ./courier-service-core/
COPY --from=build /app/courier-service-core/dist/ ./courier-service-core/dist/

COPY --from=build /app/courier-service-cli/package.json ./courier-service-cli/
COPY --from=build /app/courier-service-cli/package-lock.json ./courier-service-cli/
RUN cd courier-service-cli && npm ci --omit=dev

COPY --from=build /app/courier-service-cli/dist/ ./courier-service-cli/dist/
COPY --from=build /app/courier-service-cli/bin/ ./courier-service-cli/bin/

COPY --from=build /app/courier-service-api/package.json ./courier-service-api/
COPY --from=build /app/courier-service-api/package-lock.json ./courier-service-api/
RUN cd courier-service-api && npm ci --omit=dev

COPY --from=build /app/courier-service-api/dist/ ./courier-service-api/dist/

ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/api/health || exit 1

CMD ["node", "courier-service-api/dist/index.js"]
