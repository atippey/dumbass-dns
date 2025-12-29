# dumbass-dns

Low-effort dynamic DNS updater for AWS Route53, running as a Kubernetes CronJob.

## What it does

Automatically keeps a Route53 A record updated with your current public IP address. Perfect for home labs, remote access to services behind dynamic IPs, or any situation where you need a domain name to always point to your current public IP.

- Checks your current public IP via ipify.org
- Compares it to your Route53 A record
- Updates the record only if the IP has changed
- Runs on a schedule (default: every 5 minutes)

## Requirements

- Kubernetes cluster (tested on Raspberry Pi k3s with ARM64)
- AWS Route53 hosted zone
- AWS credentials with Route53 permissions
- Docker (for building/pushing images)
- Helm 3

## Quick Start

### 1. Set up environment variables

Create a `.env` file:

```bash
# Docker registry credentials (for ghcr.io)
CR_USERNAME=your-github-username
CR_PAT=your-github-personal-access-token
CR_EMAIL=your-email@example.com

# AWS credentials
AWS_ACCESS_KEY_ID=your-aws-access-key
AWS_SECRET_ACCESS_KEY=your-aws-secret-key
```

### 2. Configure your DNS settings

Edit `values.yaml`:

```yaml
dns:
  domain: "home.example.com"  # Your domain name
  zoneId: "Z1234567890ABC"    # Your Route53 hosted zone ID
  ttl: "300"
  timeout: "30"

image:
  repository: ghcr.io/your-username/dumbass-dns/refresh
  tag: "main"  # or your release tag

imagePullSecrets:
  - name: ghcr-secret

cronjob:
  schedule: "*/5 * * * *"  # Every 5 minutes
```

### 3. Build and push the Docker image

```bash
make push
```

This builds the ARM64 image and pushes it to GitHub Container Registry.

### 4. Create Kubernetes secrets

Create the Docker registry secret:
```bash
make docker-secret
```

Create the AWS credentials secret:
```bash
make aws-secret
```

### 5. Install the Helm chart

```bash
make install
```

### 6. Test it manually (optional)

Trigger a manual run:
```bash
make run
```

## Architecture

- **Platform**: Built for `linux/arm64` (Raspberry Pi compatible)
- **Base Image**: Python 3.12 Alpine
- **Deployment**: Kubernetes CronJob
- **Dependencies**: boto3, requests

## Configuration

The Helm chart supports various configuration options in `values.yaml`:

### DNS Settings
- `dns.domain`: The domain name to update
- `dns.zoneId`: Route53 hosted zone ID
- `dns.ttl`: TTL for the DNS record (default: 300)
- `dns.timeout`: HTTP request timeout (default: 30)

### CronJob Settings
- `cronjob.schedule`: Cron schedule (default: "*/5 * * * *")
- `cronjob.successfulJobsHistoryLimit`: Number of successful jobs to keep (default: 3)
- `cronjob.failedJobsHistoryLimit`: Number of failed jobs to keep (default: 1)

### AWS Credentials
- Option 1: Use Kubernetes secret (default)
  - `aws.credentialsSecret`: Name of the secret containing AWS credentials
- Option 2: Use IRSA (IAM Roles for Service Accounts)
  - `aws.useIRSA`: true
  - `serviceAccount.annotations`: Add IRSA role ARN

### Resources
The chart includes sensible resource limits for lightweight deployment:
- CPU: 100m request, 200m limit
- Memory: 64Mi request, 128Mi limit

## Development

### Linting
```bash
make lint
```

### Build locally
```bash
make docker
```

### View current release image
```bash
make show-current-release-image
```

## How it works

1. CronJob runs on schedule
2. Python script queries ipify.org for current public IP
3. Script queries Route53 for current A record value
4. If IPs differ, script updates Route53 with UPSERT operation
5. If IPs match, no action taken

## License

See LICENSE file.
