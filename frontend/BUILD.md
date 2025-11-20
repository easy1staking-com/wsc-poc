# Build Guide

## Multi-Environment Build System

The frontend supports building for multiple Cardano networks: Preview, Preprod, and Mainnet.

## Usage

### Building for Different Environments

```bash
# Build for Preview (default)
./build.sh preview

# Build for Preprod
./build.sh preprod

# Build for Mainnet
./build.sh mainnet
```

If no environment is specified, it defaults to `preview`:
```bash
./build.sh  # Same as ./build.sh preview
```

## Environment Configuration Files

Each environment has its own configuration file:

- `.env.preview` - Preview testnet configuration
- `.env.preprod` - Preprod testnet configuration
- `.env.mainnet` - Mainnet production configuration

### Configuration Format

Each file contains:
```bash
NEXT_PUBLIC_BLOCKFROST_API_KEY=<your-blockfrost-key>
NETWORK=<Preview|Preprod|Mainnet>
NEXT_PUBLIC_API_URL=<your-backend-api-url>
```

## Docker Images

The build script creates Docker images with environment-specific tags:

### Image Naming Convention

For a git version `v1.2.3` and environment `preview`:
- `easy1staking/programmable-tokens-ui:v1.2.3-preview`
- `easy1staking/programmable-tokens-ui:preview-latest`

### Examples

**Preview:**
- `programmable-tokens-ui:35e8f85-preview`
- `programmable-tokens-ui:preview-latest`

**Preprod:**
- `programmable-tokens-ui:35e8f85-preprod`
- `programmable-tokens-ui:preprod-latest`

**Mainnet:**
- `programmable-tokens-ui:35e8f85-mainnet`
- `programmable-tokens-ui:mainnet-latest`

## Deployment

### Kubernetes

Update your Kubernetes deployment to use the environment-specific image:

```yaml
spec:
  containers:
  - name: frontend
    image: easy1staking/programmable-tokens-ui:preview-latest
    # or
    image: easy1staking/programmable-tokens-ui:mainnet-latest
```

### Local Testing

To build without pushing to Docker registry, remove the `--push` flag from `build.sh`:

```bash
# In build.sh, line 55, remove:
  --push \
```

## Configuration Before Building

### 1. Update Preprod Configuration

Edit `.env.preprod` and replace:
- `preprodYOUR_PREPROD_KEY_HERE` with your actual Preprod Blockfrost API key
- Verify `NEXT_PUBLIC_API_URL` points to your Preprod backend

### 2. Update Mainnet Configuration

Edit `.env.mainnet` and replace:
- `mainnetYOUR_MAINNET_KEY_HERE` with your actual Mainnet Blockfrost API key
- Verify `NEXT_PUBLIC_API_URL` points to your Mainnet backend

## Troubleshooting

### Invalid environment error

```
Error: Invalid environment 'prod'
Usage: ./build.sh <environment>
Valid environments: preview, preprod, mainnet
```

**Solution:** Use one of the valid environment names: `preview`, `preprod`, or `mainnet`

### Environment file not found

```
Error: Environment file '.env.preprod' not found
```

**Solution:** Ensure the environment config file exists in the frontend directory

### Docker build fails

**Solution:**
1. Check that all environment variables in the `.env.<environment>` file are set
2. Verify Docker is running
3. Ensure you're logged into Docker Hub: `docker login`

## CI/CD Integration

### GitHub Actions Example

```yaml
- name: Build and push Docker image
  run: |
    cd frontend
    ./build.sh ${{ matrix.environment }}
  strategy:
    matrix:
      environment: [preview, preprod, mainnet]
```

### GitLab CI Example

```yaml
build:preview:
  script:
    - cd frontend
    - ./build.sh preview

build:mainnet:
  script:
    - cd frontend
    - ./build.sh mainnet
  only:
    - main
```
