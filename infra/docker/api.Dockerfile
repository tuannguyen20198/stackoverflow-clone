# ===== BUILDER =====
FROM node:22-alpine AS builder
WORKDIR /app

RUN npm install -g pnpm

COPY . .
RUN pnpm install --frozen-lockfile
RUN pnpm --filter @apps/api-gateway build

# ===== RUNNER =====
FROM node:22-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
RUN npm install -g pnpm

# Copy toàn bộ từ builder (bao gồm cả node_modules đã có)
COPY --from=builder /app ./

# Prune dev dependencies
RUN pnpm prune --prod

EXPOSE 4000
CMD ["node", "apps/api-gateway/dist/main.js"]