# Docker Deployment Guide

## Overview
This Next.js application includes server-side features (API rewrites, server components) and is configured for Docker deployment using a multi-stage build for optimized production images.

## Quick Start

### Using Docker Compose (Recommended)
```bash
# Development
NEXT_PUBLIC_API_URL=http://localhost:8080 npm run docker:up

# Production
NEXT_PUBLIC_API_URL=https://your-api.com npm run docker:up

# Stop
npm run docker:down

# View logs
npm run docker:logs
```

### Using Docker CLI
```bash
# Build image
npm run docker:build

# Build for production with custom API URL
NEXT_PUBLIC_API_URL=https://api.production.com npm run docker:build:prod

# Run container
npm run docker:run

# Or with custom API URL
NEXT_PUBLIC_API_URL=https://api.production.com docker run -p 3000:3000 \
  -e NEXT_PUBLIC_API_URL=https://api.production.com \
  wsc-frontend:latest
```

## Environment Configuration

### Build-time Variables
Set these during image build:
- `NEXT_PUBLIC_API_URL` - Backend API URL (embedded in the build)

### Runtime Variables
Set these when running the container:
- `NEXT_PUBLIC_API_URL` - Can override build-time setting
- `PORT` - Default: 3000
- `NODE_ENV` - Default: production

### Environment Files
- `.env.development` - Local development
- `.env.production` - Production builds
- `.env.docker` - Docker defaults (template)

## Server-Side Features
✅ **Yes, server-side calls work in Docker!**

This app uses:
- **API Rewrites** (`next.config.js:92-103`) - Proxies `/api/v1/*` and `/blockfrost-key` to backend
- **App Router** - Supports Server Components and Server Actions
- **Standalone Output** - Optimized Node.js server with minimal dependencies

The Next.js server runs inside the container and handles:
- Server-side rendering (SSR)
- API route proxying
- Static file serving

## Production Deployment

### Build for production
```bash
# Set your production API URL
export NEXT_PUBLIC_API_URL=https://api.production.com

# Build image
docker build -t wsc-frontend:prod \
  --build-arg NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL .
```

### Run in production
```bash
docker run -d \
  --name wsc-frontend \
  -p 3000:3000 \
  -e NEXT_PUBLIC_API_URL=https://api.production.com \
  --restart unless-stopped \
  wsc-frontend:prod
```

### With Docker Compose
```bash
# Create production env file
cp .env.docker .env.docker.local
# Edit .env.docker.local with your production values

# Deploy
docker-compose --env-file .env.docker.local up -d
```

## Image Details
- **Base**: node:20-alpine
- **Size**: ~150-200MB (optimized)
- **User**: Non-root (nextjs:1001)
- **Output**: Standalone (minimal dependencies)
- **Exposed Port**: 3000

## Networking
If running both frontend and backend in Docker:
```yaml
# docker-compose.yml example
services:
  backend:
    # ... your backend config
    networks:
      - app-network

  frontend:
    build: .
    environment:
      - NEXT_PUBLIC_API_URL=http://backend:8080
    networks:
      - app-network
```

## Troubleshooting

### API calls not working
- Check `NEXT_PUBLIC_API_URL` is set correctly
- Verify network connectivity between frontend and backend
- Check logs: `docker logs <container-id>`

### Build fails
- Ensure dependencies install: `npm ci` locally first
- Check Node version compatibility (requires Node 20+)

### Container won't start
- Check port 3000 isn't already in use
- Review logs: `docker-compose logs frontend`
