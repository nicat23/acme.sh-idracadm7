# ACME.sh with Dell iDRAC Support

A containerized version of the popular ACME.sh SSL certificate management tool with integrated Dell iDRAC support for enterprise server environments.

**Docker Hub**: [nicat23/idracadm7](https://hub.docker.com/repository/docker/nicat23/idracadm7)

## About

This Docker image combines the power of [acme.sh](https://github.com/acmesh-official/acme.sh) - a pure Unix shell script implementing the ACME client protocol - with Dell iDRAC management capabilities. It's designed for enterprise environments where SSL certificates need to be automatically deployed to Dell servers via iDRAC.

## Credits

- **Original ACME.sh Project**: [acmesh-official/acme.sh](https://github.com/acmesh-official/acme.sh)
- **ACME.sh Author**: Neil Pang and contributors
- **Dell iDRAC Integration**: This image includes Dell Server Administrator tools for iDRAC management
- **iDRAC Deployment Hook Inspiration**: The included `idrac.sh` deploy hook was inspired by [societa-astronomica-g-v-schiaparelli/acme-idrac7](https://github.com/societa-astronomica-g-v-schiaparelli/acme-idrac7) and [kroy-the-rabbit/acme_idrac_deployment](https://github.com/kroy-the-rabbit/acme_idrac_deployment)
- Project Docker Hub Repository: [https://hub.docker.com/repository/docker/nicat23/idracadm7/]

## Features

- ✅ Full ACME.sh functionality for Let's Encrypt and other ACME CAs
- ✅ Dell iDRAC integration via `racadm` command
- ✅ Automated iDRAC certificate deployment with included `idrac.sh` deploy hook
- ✅ Support for multiple DNS providers and deployment hooks
- ✅ Automatic certificate renewal via cron
- ✅ Custom deploy, DNS API, and notification scripts support
- ✅ Based on Alpine Linux for minimal footprint
- ✅ Runs as non-root user (UID/GID 1000) by default for improved security
- ✅ Configurable user permissions via PUID/PGID environment variables

## Quick Start

### Basic Certificate Issuance
```bash
# Runs as apps user (UID/GID 1000) by default
docker run --rm -v "$(pwd)/certs:/acme.sh" \
  nicat23/idracadm7:v1 \
  --issue -d example.com --standalone
```

### Custom User Permissions
```bash
# Run with custom UID/GID to match your host user
docker run --rm \
  -v "$(pwd)/certs:/acme.sh" \
  -e PUID=$(id -u) \
  -e PGID=$(id -g) \
  nicat23/idracadm7:v1 \
  --issue -d example.com --standalone
```

### Automated iDRAC Certificate Deployment with Deploy Hook

Use the included `idrac.sh` deploy hook for streamlined certificate deployment:

```bash
# Set environment variables for iDRAC connection
export DEPLOY_IDRAC_HOST="192.168.1.100"
export DEPLOY_IDRAC_USER="root"
export DEPLOY_IDRAC_PASS="password"

# Issue and automatically deploy certificate to iDRAC
docker run --rm \
  -v "$(pwd)/certs:/acme.sh" \
  -e DEPLOY_IDRAC_HOST \
  -e DEPLOY_IDRAC_USER \
  -e DEPLOY_IDRAC_PASS \
  -e CF_Token="your-cloudflare-token" \
  nicat23/idracadm7:v1 \
  --issue --dns dns_cf -d "idrac.example.com" --deploy-hook idrac.sh
```

Or deploy an existing certificate:

```bash
# Deploy existing certificate using the idrac.sh hook
docker run --rm \
  -v "$(pwd)/certs:/acme.sh" \
  -e DEPLOY_IDRAC_HOST="192.168.1.100" \
  -e DEPLOY_IDRAC_USER="root" \
  -e DEPLOY_IDRAC_PASS="password" \
  nicat23/idracadm7:v1 \
  --deploy -d "idrac.example.com" --deploy-hook idrac.sh
```

### Manual iDRAC Certificate Deployment
```bash
docker run --rm -v "$(pwd)/certs:/acme.sh" \
  nicat23/idracadm7:v1 \
  racadm -r 192.168.1.100 -u root -p password sslcertupload -t 1 -f /acme.sh/example.com/fullchain.cer
```

### Run as Daemon (with automatic renewals)
```bash
docker run -d --name acme-daemon \
  -v "$(pwd)/certs:/acme.sh" \
  nicat23/idracadm7:v1 daemon
```

## Usage

### Available Commands

The container supports all standard acme.sh commands:

```bash
# Issue a certificate
docker run --rm -v "$(pwd)/acme.sh:/acme.sh" \
  nicat23/idracadm7:v1 \
  --issue -d example.com --dns dns_cloudflare

# Renew certificates
docker run --rm -v "$(pwd)/acme.sh:/acme.sh" \
  nicat23/idracadm7:v1 \
  --renew-all

# List certificates
docker run --rm -v "$(pwd)/acme.sh:/acme.sh" \
  nicat23/idracadm7:v1 \
  --list
```

### Dell iDRAC Management

Use the `racadm` command directly:

```bash
# Check iDRAC status
docker run --rm nicat23/idracadm7:v1 \
  racadm -r 192.168.1.100 -u root -p password getconfig -g cfgRacTuning

# Upload SSL certificate to iDRAC
docker run --rm -v "$(pwd)/acme.sh:/acme.sh" \
  nicat23/idracadm7:v1 \
  racadm -r 192.168.1.100 -u root -p password sslcertupload -t 1 -f /acme.sh/example.com/fullchain.cer
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `LE_CONFIG_HOME` | `/acme.sh` | ACME.sh configuration directory |
| `AUTO_UPGRADE` | `1` | Enable automatic acme.sh upgrades |
| `PUID` | `1000` | User ID for running the container process |
| `PGID` | `1000` | Group ID for running the container process |
| `USERNAME` | `apps` | Username for the container user |
| `DEPLOY_IDRAC_HOST` | - | iDRAC IP address or hostname for deploy hook |
| `DEPLOY_IDRAC_USER` | - | iDRAC username for deploy hook |
| `DEPLOY_IDRAC_PASS` | - | iDRAC password for deploy hook |

## Volumes

- `/acme.sh` - Persistent storage for certificates and configuration

### Configuration Structure

The `/acme.sh` mount point contains your persistent configuration and certificates:

```
/acme.sh/
├── account.conf          # Main configuration file
├── http.header          # HTTP headers configuration
├── acme.sh.log          # Log file (if LOG_FILE is configured)
└── [domain]/            # Certificate directories (created after issuance)
    ├── [domain].cer     # Certificate file
    ├── [domain].key     # Private key
    ├── fullchain.cer    # Full certificate chain
    └── ca.cer           # CA certificate
```

### Custom Configuration

You can customize your acme.sh environment through the `account.conf` file in your mounted volume. **Important**: According to the acme.sh author, this file should be modified using acme.sh's built-in commands rather than direct editing, as the script manages this configuration automatically.

**Migration from existing acme.sh installation**: If you already have acme.sh running elsewhere, you can copy your existing `account.conf`, `http.header` files, and entire domain certificate directories directly into the `/acme.sh` mount point. This provides a drop-in solution that preserves your configuration, DNS provider credentials, existing certificates, and renewal schedules without any reconfiguration needed.

#### Recommended Configuration Method

Use acme.sh commands to set configuration values:

```bash
# Set account email
docker run --rm -v "$(pwd)/acme.sh:/acme.sh" \
  nicat23/idracadm7:v1 \
  --set-notify --notify-hook mail --notify-email your-email@example.com

# Set default CA server
docker run --rm -v "$(pwd)/acme.sh:/acme.sh" \
  nicat23/idracadm7:v1 \
  --set-default-ca --server letsencrypt

# Configure DNS provider credentials (example with Cloudflare)
docker run --rm -v "$(pwd)/acme.sh:/acme.sh" \
  -e CF_Token="your-cloudflare-token" \
  -e CF_Account_ID="your-cloudflare-account-id" \
  nicat23/idracadm7:v1 \
  --issue -d example.com --dns dns_cf
```

#### Example account.conf Structure

After using acme.sh commands, your `account.conf` might look like this:

```bash
# This file is automatically managed by acme.sh
ACCOUNT_EMAIL='your-email@example.com'
SAVED_CF_Token='your-cloudflare-token'
SAVED_CF_Account_ID='your-cloudflare-account-id'
DEFAULT_ACME_SERVER='https://acme-v02.api.letsencrypt.org/directory'
LOG_FILE="/acme.sh/acme.sh.log"
LOG_LEVEL=1
AUTO_UPGRADE='1'

# iDRAC deploy hook configuration (set when using the deploy hook)
DEPLOY_IDRAC_HOST='192.168.1.100'
DEPLOY_IDRAC_USER='root'
DEPLOY_IDRAC_PASS='password'
```

The acme.sh script automatically saves DNS provider credentials and deploy hook settings when you use them, creating persistent configuration that survives container restarts.

## User Permissions & Security

This container runs as a non-root user by default for improved security:

- **Default User**: `apps` (UID/GID 1000)
- **Configurable**: Use `PUID` and `PGID` environment variables to match your host user
- **File Permissions**: The container automatically sets proper ownership of the `/acme.sh` volume

### Permission Examples

**Default behavior (recommended):**
```bash
docker run --rm -v "$(pwd)/certs:/acme.sh" \
  nicat23/idracadm7:v1 --list
```

**Match your host user ID:**
```bash
docker run --rm \
  -v "$(pwd)/certs:/acme.sh" \
  -e PUID=$(id -u) \
  -e PGID=$(id -g) \
  nicat23/idracadm7:v1 --list
```

**Run as root (when required for specific operations):**
```bash
docker run --rm \
  -v "$(pwd)/certs:/acme.sh" \
  -e PUID=0 \
  -e PGID=0 \
  nicat23/idracadm7:v1 --list
```

## Custom Scripts

This image supports custom deploy hooks, DNS API scripts, and notification hooks by copying them into the appropriate directories during the build:
- **DNS API scripts**: Custom DNS provider scripts in the `dnsapi/` directory  
- **Notification hooks**: Custom notification scripts in the `notify/` directory

The included folder structure:
```
.
├── Dockerfile
├── acme.sh
├── deploy/
│   └── idrac.sh
├── dnsapi/
└── notify/
```

## Examples

### Complete Workflow with DNS Challenge and iDRAC Deploy Hook

```bash
# Single command to issue and deploy certificate to iDRAC
docker run --rm \
  -v "$(pwd)/acme.sh:/acme.sh" \
  -e CF_Token="your-cloudflare-token" \
  -e CF_Account_ID="your-account-id" \
  -e DEPLOY_IDRAC_HOST="idrac.example.com" \
  -e DEPLOY_IDRAC_USER="root" \
  -e DEPLOY_IDRAC_PASS="password" \
  nicat23/idracadm7:v1 \
  --issue -d idrac.example.com --dns dns_cf --deploy-hook idrac.sh
```

### Manual Workflow with Individual Commands

```bash
# 1. Issue certificate using Cloudflare DNS
docker run --rm \
  -v "$(pwd)/acme.sh:/acme.sh" \
  -e CF_Token="your-cloudflare-token" \
  -e CF_Account_ID="your-account-id" \
  nicat23/idracadm7:v1 \
  --issue -d idrac.example.com --dns dns_cf

# 2. Deploy to iDRAC
docker run --rm \
  -v "$(pwd)/acme.sh:/acme.sh" \
  nicat23/idracadm7:v1 \
  racadm -r idrac.example.com -u root -p password \
  sslcertupload -t 1 -f /acme.sh/idrac.example.com/fullchain.cer

# 3. Upload private key
docker run --rm \
  -v "$(pwd)/acme.sh:/acme.sh" \
  nicat23/idracadm7:v1 \
  racadm -r idrac.example.com -u root -p password \
  sslkeyupload -t 1 -f /acme.sh/idrac.example.com/idrac.example.com.key

# 4. Reset iDRAC to apply new certificate
docker run --rm \
  nicat23/idracadm7:v1 \
  racadm -r idrac.example.com -u root -p password racreset soft
```

## Docker Compose Example

```yaml
version: '3.8'
services:
  acme-sh:
    image: nicat23/idracadm7:v1
    container_name: acme-daemon
    volumes:
      - ./certs:/acme.sh
    environment:
      - PUID=1000
      - PGID=1000
      - AUTO_UPGRADE=1
      # Add your DNS provider credentials here
      - CF_Token=your-cloudflare-token
    command: daemon
    restart: unless-stopped
```

## Supported Platforms

- `linux/amd64` (Linux environments)
- `windows/amd64` (Windows with Docker Desktop)
- `darwin/amd64` (macOS - untested)

**Note**: ARM64 support is not available as Dell EMC Server Administrator tools only support x86_64 architecture.

## License

This Docker image is provided as-is. Please refer to the original [acme.sh license](https://github.com/acmesh-official/acme.sh/blob/master/LICENSE.md) for the underlying ACME client.

## Contributing

Issues and pull requests are welcome. For major changes related to the core acme.sh functionality, please contribute to the [upstream project](https://github.com/acmesh-official/acme.sh).

## Support

- For acme.sh specific issues: [acme.sh GitHub Issues](https://github.com/acmesh-official/acme.sh/issues)
- For Dell iDRAC questions: Dell's official documentation
- For Docker image issues: Open an issue in this repository

## Links

- [acme.sh Official Repository](https://github.com/acmesh-official/acme.sh)
- [acme.sh Documentation](https://github.com/acmesh-official/acme.sh/wiki)
- [Let's Encrypt](https://letsencrypt.org/)
- [Dell iDRAC Documentation](https://www.dell.com/support/manuals/us/en/04/idrac9-lifecycle-controller-v3.30.30.30/idrac_3.30.30.30_ug/)
