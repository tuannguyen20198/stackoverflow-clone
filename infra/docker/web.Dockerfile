# ===== BUILDER =====
FROM node:22-bullseye AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install pnpm globally and dependencies
RUN npm install -g pnpm \
    && pnpm install --frozen-lockfile

# Copy all app files
COPY . .

# Rebuild lightningcss for correct platform (ARM64)
RUN pnpm rebuild lightningcss

# Build Next.js app
RUN pnpm --filter @apps/web build

# ===== RUNNER =====
FROM node:22-bullseye AS runner

WORKDIR /app

# Install pnpm
RUN npm install -g pnpm

# Copy only necessary files from builder
COPY --from=builder /app/apps/web . 
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/pnpm-lock.yaml ./pnpm-lock.yaml

# Expose port
EXPOSE 3000

# Start the app
CMD ["pnpm", "start"]
