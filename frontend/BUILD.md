# Build Guide

## Runtime Environment Configuration

The frontend uses **runtime environment variables** instead of build-time configuration. This means:
- ✅ Build **once**, deploy **everywhere**
- ✅ No rebuild needed to change configuration
- ✅ Configure via Kubernetes ConfigMaps/Secrets

## Building

### Simple Build

```bash
# Build and push with version tag
./build.sh

# This creates:
# - easy1staking/programmable-tokens-ui:v1.2.3
# - easy1staking/programmable-tokens-ui:latest
```

### Build with Environment Tag (Optional)

```bash
# Build with environment-specific tag for organization
./build.sh preview

# This creates:
# - easy1staking/programmable-tokens-ui:v1.2.3-preview
# - easy1staking/programmable-tokens-ui:preview-latest
```

**Note:** The image is identical regardless of tag. Tags are just for organization.

## Runtime Configuration

Set these environment variables when running the container:

- `NEXT_PUBLIC_API_URL` - Backend API URL (e.g., `https://preview-api.programmabletokens.xyz`)
- `NEXT_PUBLIC_BLOCKFROST_API_KEY` - Blockfrost API key for the network
- `NETWORK` - Network name (`Preview`, `Preprod`, or `Mainnet`)

## Deployment

### Kubernetes Example

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  template:
    spec:
      containers:
      - name: frontend
        image: easy1staking/programmable-tokens-ui:latest
        ports:
        - containerPort: 3000
        env:
        - name: NEXT_PUBLIC_API_URL
          value: "https://preview-api.programmabletokens.xyz"
        - name: NEXT_PUBLIC_BLOCKFROST_API_KEY
          valueFrom:
            secretKeyRef:
              name: blockfrost-secrets
              key: preview-api-key
        - name: NETWORK
          value: "Preview"
```

### Using ConfigMaps and Secrets

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-config
data:
  NEXT_PUBLIC_API_URL: "https://preview-api.programmabletokens.xyz"
  NETWORK: "Preview"
---
apiVersion: v1
kind: Secret
metadata:
  name: blockfrost-secrets
type: Opaque
stringData:
  preview-api-key: "preview6rf9Lym3f9XQrTDnxSBbAGwvz5mNafdz"
  preprod-api-key: "preprodYOUR_KEY_HERE"
  mainnet-api-key: "mainnetYOUR_KEY_HERE"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  template:
    spec:
      containers:
      - name: frontend
        image: easy1staking/programmable-tokens-ui:latest
        ports:
        - containerPort: 3000
        envFrom:
        - configMapRef:
            name: frontend-config
        env:
        - name: NEXT_PUBLIC_BLOCKFROST_API_KEY
          valueFrom:
            secretKeyRef:
              name: blockfrost-secrets
              key: preview-api-key
```

### Docker Run Example

```bash
docker run -p 3000:3000 \
  -e NEXT_PUBLIC_API_URL=https://preview-api.programmabletokens.xyz \
  -e NEXT_PUBLIC_BLOCKFROST_API_KEY=preview6rf9Lym3f9XQrTDnxSBbAGwvz5mNafdz \
  -e NETWORK=Preview \
  easy1staking/programmable-tokens-ui:latest
```

### Docker Compose

```bash
docker-compose up
```

Edit `docker-compose.yml` to set your environment variables.

## Local Development

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Build for production
npm run build

# Start production server
npm start
```

## Architecture

- **Next.js 15** with App Router
- **Server-side rendering** for better performance and SEO
- **API rewrites** - `/api/v1/*` requests are proxied to backend server-side (no CORS issues)
- **Port 3000** - Next.js server port

## Switching Environments

To switch from Preview to Preprod or Mainnet:

1. Update environment variables in Kubernetes ConfigMap/Secret
2. Restart pods: `kubectl rollout restart deployment/frontend`

No rebuild required!
