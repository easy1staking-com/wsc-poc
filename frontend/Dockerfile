# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source files
COPY . .

# Build-time arguments for Next.js
ARG NEXT_PUBLIC_API_URL
ARG NEXT_PUBLIC_BLOCKFROST_API_KEY
ARG NETWORK

# Set as env vars so they're available during build
ENV NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}
ENV NEXT_PUBLIC_BLOCKFROST_API_KEY=${NEXT_PUBLIC_BLOCKFROST_API_KEY}
ENV NETWORK=${NETWORK}

# Build the Next.js app
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

# NOTE: NEXT_PUBLIC_* vars must be set at BUILD time (see ARGs above)
# To change backend URL after build, use Option 2 below

# Start Next.js server
CMD ["npm", "start"]
