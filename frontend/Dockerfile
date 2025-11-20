# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source files
COPY . .

# Build the Next.js app (env vars will be provided at runtime)
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

# Runtime env vars (set these in Kubernetes/docker run):
# - NEXT_PUBLIC_API_URL (e.g., https://preview-api.programmabletokens.xyz)
# - NEXT_PUBLIC_BLOCKFROST_API_KEY
# - NETWORK (Preview, Preprod, or Mainnet)

# Start Next.js server
CMD ["npm", "start"]
