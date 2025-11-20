# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source files
COPY . .

# Build the Next.js app
# No environment-specific variables needed at build time!
# All config is loaded at runtime from env vars
RUN npm run build

# Production stage - run Next.js server
FROM node:20-alpine AS runner

WORKDIR /app

# Set NODE_ENV
ENV NODE_ENV=production

# Copy necessary files from builder
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/next.config.js ./next.config.js

# Expose Next.js port
EXPOSE 3000

# Runtime environment variables (set these in Kubernetes/docker-compose/docker run):
# - API_URL: Backend API URL (e.g., http://wsc:8080 or http://localhost:8080)
# - BLOCKFROST_API_KEY: Blockfrost project ID (e.g., preview6rf9Lym3f9XQrTDnxSBbAGwvz5mNafdz)
# - NETWORK: Cardano network (Preview, Preprod, or Mainnet)
#
# These are loaded at runtime, so one build works for all environments!

# Start Next.js server
CMD ["npm", "start"]
