# ACME.sh with Dell iDRAC7 Support

![Docker Pulls](https://img.shields.io/docker/pulls/nicat23/idracadm7)
![Docker Image Version](https://img.shields.io/docker/v/nicat23/idracadm7/v2)
![License](https://img.shields.io/badge/license-GPL-blue)

A production-ready containerized solution that combines [ACME.sh](https://github.com/acmesh-official/acme.sh) SSL certificate automation with integrated Dell iDRAC management capabilities. Designed for enterprise environments requiring automated certificate deployment to Dell servers.

## 🚀 Features

### Core Functionality
- **Complete ACME.sh Integration**: Full support for Let's Encrypt and RFC8555-compliant Certificate Authorities
- **Native iDRAC Support**: Built-in `racadm` tools for seamless Dell server management
- **Automated Deployment**: Integrated `idrac.sh` deploy hook for streamlined certificate installation
- **Multi-DNS Provider**: Support for 100+ DNS providers including Cloudflare, AWS Route53, and more
- **Certificate Lifecycle**: Automated issuance, renewal, and deployment with cron support

### Enterprise Features
- **Security Hardened**: Minimal Alpine Linux base with security best practices
- **Production Ready**: Persistent configuration, logging, and monitoring support  
- **Multi-Architecture**: Native support for `linux/amd64` and `linux/arm64`
- **Custom Hooks**: Extensible architecture for custom deploy, DNS, and notification scripts
- **Migration Friendly**: Drop-in replacement for existing ACME.sh installations

## 📋 Quick Start

### Basic Certificate Issuance
```bash
docker run --rm -v "$(pwd)/acme.sh:/acme.sh" \
  nicat23/idracadm7:v2 \
  --issue -d example.com --standalone
```

### Issue and Deploy to iDRAC (One Command)
```bash
# Set your environment variables
export DEPLOY_IDRAC_HOST="idrac.example.com"
export DEPLOY_IDRAC_USER="root"  
export DEPLOY_IDRAC_PASS="your-password"
export CF_Token="your-cloudflare-token"

# Issue certificate and automatically deploy to iDRAC
docker run --rm \
  -v "$(pwd)/acme.sh:/acme.sh" \
  -e DEPLOY_IDRAC_HOST \
  -e DEPLOY_IDRAC_USER \
  -e DEPLOY_IDRAC_PASS \
  -e CF_Token \
  nicat23/idracadm7:v2 \
  --issue --dns dns_cf -d "idrac.example.com" --deploy-hook idrac.sh
```

## 🔧 Installation & Usage

### Docker Compose (Recommended)
Create a `docker-compose.yml` file:

```yaml
version: '3.8'

services:
  acme-daemon:
    image: nicat23/idracadm7:v2
    container_name: acme-daemon
    restart: unless-stopped
    volumes:
      - ./acme.sh:/acme.sh
      - ./logs:/var/log/acme
    environment:
      - AUTO_UPGRADE=1
      - LOG_LEVEL=2
      # DNS Provider Credentials
      - CF_Token=your-cloudflare-token
      - CF_Account_ID=your-account-id
      # iDRAC Configuration
      - DEPLOY_IDRAC_HOST=idrac.example.com
      - DEPLOY_IDRAC_USER=root
      - DEPLOY_IDRAC_PASS=your-password
    command: daemon
    security_opt:
      - no-new-privileges:true
    mem_limit: 256m
    cpus: 0.5
    networks:
      - acme-network

networks:
  acme-network:
    driver: bridge
```

Start the service:
```bash
docker compose up -d
```

### Standalone Container Usage

#### Certificate Management
```bash
# Issue certificate with DNS validation
docker run --rm -v "$(pwd)/acme.sh:/acme.sh" \
  -e CF_Token="your-token" \
  nicat23/idracadm7:v2 \
  --issue -d example.com --dns dns_cf

# Renew all certificates
docker run --rm -v "$(pwd)/acme.sh:/acme.sh" \
  nicat23/idracadm7:v2 \
  --renew-all

# List all certificates
docker run --rm -v "$(pwd)/acme.sh:/acme.sh" \
  nicat23/idracadm7:v2 \
  --list
```

#### Direct iDRAC Management
```bash
# Check iDRAC SSL certificate status
docker run --rm nicat23/idracadm7:v2 \
  racadm -r 192.168.1.100 -u root -p password \
  sslcertview

# Upload certificate to iDRAC
docker run --rm -v "$(pwd)/acme.sh:/acme.sh" \
  nicat23/idracadm7:v2 \
  racadm -r 192.168.1.100 -u root -p password \
  sslcertupload -t 1 -f /acme.sh/example.com/fullchain.cer

# Reset iDRAC to apply new certificate
docker run --rm nicat23/idracadm7:v2 \
  racadm -r 192.168.1.100 -u root -p password \
  racreset soft
```

## 🔐 Dell iDRAC Integration

### Using the Built-in Deploy Hook

The container includes an optimized `idrac.sh` deploy hook that automatically:
- Uploads the certificate and private key to iDRAC
- Performs certificate validation
- Gracefully resets iDRAC to apply changes
- Provides detailed logging and error handling

#### Environment Variables for Deploy Hook
| Variable | Required | Description |
|----------|----------|-------------|
| `DEPLOY_IDRAC_HOST` | ✅ | iDRAC IP address or hostname |
| `DEPLOY_IDRAC_USER` | ✅ | iDRAC username (typically `root`) |
| `DEPLOY_IDRAC_PASS` | ✅ | iDRAC password |
| `DEPLOY_IDRAC_SLOT` | ❌ | Certificate slot (default: `1`) |

#### Complete Workflow Example
```bash
#!/bin/bash

# Configuration
export DEPLOY_IDRAC_HOST="192.168.1.100"
export DEPLOY_IDRAC_USER="root"
export DEPLOY_IDRAC_PASS="your-secure-password"
export CF_Token="your-cloudflare-token"
export DOMAIN="idrac.example.com"

# Issue certificate using Cloudflare DNS
docker run --rm \
  -v "$(pwd)/acme.sh:/acme.sh" \
  -e CF_Token \
  nicat23/idracadm7:v2 \
  --issue -d "$DOMAIN" --dns dns_cf

# Deploy to iDRAC using the integrated hook
docker run --rm \
  -v "$(pwd)/acme.sh:/acme.sh" \
  -e DEPLOY_IDRAC_HOST \
  -e DEPLOY_IDRAC_USER \
  -e DEPLOY_IDRAC_PASS \
  nicat23/idracadm7:v2 \
  --deploy -d "$DOMAIN" --deploy-hook idrac.sh

echo "Certificate deployed to iDRAC at $DEPLOY_IDRAC_HOST"
```

### Manual iDRAC Certificate Management
```bash
# Step-by-step manual deployment
IDRAC_HOST="192.168.1.100"
IDRAC_USER="root"
IDRAC_PASS="password"
DOMAIN="idrac.example.com"

# 1. Upload certificate
docker run --rm -v "$(pwd)/acme.sh:/acme.sh" \
  nicat23/idracadm7:v2 \
  racadm -r "$IDRAC_HOST" -u "$IDRAC_USER" -p "$IDRAC_PASS" \
  sslcertupload -t 1 -f "/acme.sh/$DOMAIN/fullchain.cer"

# 2. Upload private key  
docker run --rm -v "$(pwd)/acme.sh:/acme.sh" \
  nicat23/idracadm7:v2 \
  racadm -r "$IDRAC_HOST" -u "$IDRAC_USER" -p "$IDRAC_PASS" \
  sslkeyupload -t 1 -f "/acme.sh/$DOMAIN/$DOMAIN.key"

# 3. Verify certificate installation
docker run --rm nicat23/idracadm7:v2 \
  racadm -r "$IDRAC_HOST" -u "$IDRAC_USER" -p "$IDRAC_PASS" \
  sslcertview

# 4. Reset iDRAC to activate certificate
docker run --rm nicat23/idracadm7:v2 \
  racadm -r "$IDRAC_HOST" -u "$IDRAC_USER" -p "$IDRAC_PASS" \
  racreset soft
```

## ⚙️ Configuration

### Environment Variables

#### Core ACME.sh Configuration
| Variable | Default | Description |
|----------|---------|-------------|
| `LE_CONFIG_HOME` | `/acme.sh` | ACME.sh configuration directory |
| `AUTO_UPGRADE` | `1` | Enable automatic acme.sh upgrades |
| `LOG_LEVEL` | `1` | Logging verbosity (1-3) |
| `LOG_FILE` | `/acme.sh/acme.sh.log` | Log file location |

#### DNS Provider Credentials
| Variable | Provider | Description |
|----------|----------|-------------|
| `CF_Token` | Cloudflare | API Token |
| `CF_Account_ID` | Cloudflare | Account ID |
| `AWS_ACCESS_KEY_ID` | AWS Route53 | Access Key |
| `AWS_SECRET_ACCESS_KEY` | AWS Route53 | Secret Key |
| `GODADDY_Key` | GoDaddy | API Key |
| `GODADDY_Secret` | GoDaddy | API Secret |

> **Note**: See [ACME.sh DNS API documentation](https://github.com/acmesh-official/acme.sh/wiki/dnsapi) for complete provider list.

#### iDRAC Deploy Hook Configuration
| Variable | Default | Description |
|----------|---------|-------------|
| `DEPLOY_IDRAC_HOST` | - | iDRAC IP or hostname |
| `DEPLOY_IDRAC_USER` | - | iDRAC username |
| `DEPLOY_IDRAC_PASS` | - | iDRAC password |
| `DEPLOY_IDRAC_SLOT` | `1` | Certificate slot number |

### Volume Mounts

#### Required Volumes
- `/acme.sh` - Persistent certificate storage and configuration
- `/var/log/acme` - Log files (recommended for production)

#### Directory Structure
```
./acme.sh/
├── account.conf          # Main configuration
├── acme.sh.log           # Application logs
├── http.header           # HTTP headers config
└── [domain]/             # Certificate directories
    ├── [domain].cer      # Domain certificate
    ├── [domain].key      # Private key
    ├── fullchain.cer     # Full certificate chain
    └── ca.cer           # CA certificate
```

### Configuration Management

#### Using Built-in Commands (Recommended)
```bash
# Configure account email
docker run --rm -v "$(pwd)/acme.sh:/acme.sh" \
  nicat23/idracadm7:v2 \
  --set-notify --notify-hook mail --notify-email admin@example.com

# Set default CA
docker run --rm -v "$(pwd)/acme.sh:/acme.sh" \
  nicat23/idracadm7:v2 \
  --set-default-ca --server letsencrypt

# Configure DNS provider permanently
docker run --rm -v "$(pwd)/acme.sh:/acme.sh" \
  -e CF_Token="your-token" \
  nicat23/idracadm7:v2 \
  --issue -d temp.example.com --dns dns_cf --dry-run
```

#### Migration from Existing Installation
```bash
# Copy existing ACME.sh configuration
cp -r /path/to/existing/acme.sh/* ./acme.sh/

# Verify migration
docker run --rm -v "$(pwd)/acme.sh:/acme.sh" \
  nicat23/idracadm7:v2 \
  --list
```

## 🔒 Security Considerations

### Container Security
```bash
# Run with security restrictions
docker run --rm \
  --cap-drop=ALL \
  --cap-add=DAC_OVERRIDE \
  --cap-add=SETUID \
  --cap-add=SETGID \
  --security-opt=no-new-privileges:true \
  --read-only \
  --tmpfs /tmp \
  --tmpfs /var/tmp \
  -v "$(pwd)/acme.sh:/acme.sh" \
  nicat23/idracadm7:v2 \
  --list
```

### Network Security
```bash
# Limit network access for offline operations
docker run --rm \
  --network none \
  -v "$(pwd)/acme.sh:/acme.sh" \
  nicat23/idracadm7:v2 \
  --list
```

### Best Practices
- **Credential Management**: Use Docker secrets or external secret management
- **Network Isolation**: Deploy in isolated networks with minimal required access
- **Resource Limits**: Always set memory and CPU constraints
- **Log Monitoring**: Monitor container logs for security events
- **Regular Updates**: Keep container images updated with latest security patches

## 📚 Advanced Usage

### Custom Hooks and Scripts

The container supports custom extensions in the following directories:
- `/deploy/` - Custom deployment hooks
- `/dnsapi/` - Custom DNS provider scripts  
- `/notify/` - Custom notification hooks

### Production Deployment with Monitoring
```yaml
version: '3.8'

services:
  acme-daemon:
    image: nicat23/idracadm7:v2
    container_name: acme-daemon
    restart: unless-stopped
    volumes:
      - acme-data:/acme.sh
      - acme-logs:/var/log/acme
    environment:
      - AUTO_UPGRADE=1
      - LOG_LEVEL=2
      - LOG_FILE=/var/log/acme/acme.sh.log
    command: daemon
    healthcheck:
      test: ["CMD", "/acme.sh/acme.sh", "--version"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    security_opt:
      - no-new-privileges:true
    mem_limit: 256m
    cpus: 0.5

  log-monitor:
    image: fluent/fluent-bit:latest
    volumes:
      - acme-logs:/var/log/acme:ro
    command: >
      /fluent-bit/bin/fluent-bit
      -i tail -p path=/var/log/acme/*.log
      -o stdout
    depends_on:
      - acme-daemon

volumes:
  acme-data:
  acme-logs:
```

### Automated Renewal with Notifications
```bash
# Set up email notifications for renewals
docker run --rm -v "$(pwd)/acme.sh:/acme.sh" \
  -e MAIL_FROM="acme@example.com" \
  -e MAIL_TO="admin@example.com" \
  -e SMTP_SERVER="smtp.example.com" \
  nicat23/idracadm7:v2 \
  --set-notify --notify-hook mail
```

## 🐛 Troubleshooting

### Common Issues

#### Permission Problems
```bash
# Fix volume permissions
sudo chown -R 1000:1000 ./acme.sh
chmod -R 755 ./acme.sh
```

#### SELinux Issues
```bash
# Set SELinux contexts
sudo chcon -Rt svirt_sandbox_file_t ./acme.sh
```

#### iDRAC Connectivity
```bash
# Test iDRAC connectivity
docker run --rm nicat23/idracadm7:v2 \
  racadm -r YOUR_IDRAC_IP -u root -p password \
  getconfig -g cfgRacTuning

# Check certificate status
docker run --rm nicat23/idracadm7:v2 \
  racadm -r YOUR_IDRAC_IP -u root -p password \
  sslcertview
```

### Debug Mode
```bash
# Enable verbose logging
docker run --rm -v "$(pwd)/acme.sh:/acme.sh" \
  -e LOG_LEVEL=3 \
  nicat23/idracadm7:v2 \
  --issue -d example.com --dns dns_cf --debug 2
```

### Health Checks
```bash
# Verify container functionality
docker run --rm nicat23/idracadm7:v2 --version
docker run --rm nicat23/idracadm7:v2 racadm -v
```

## 📖 Documentation & Support

### Resources
- **ACME.sh Documentation**: [https://github.com/acmesh-official/acme.sh/wiki](https://github.com/acmesh-official/acme.sh/wiki)
- **Dell iDRAC Documentation**: Official Dell documentation
- **DNS Provider Setup**: [ACME.sh DNS API Guide](https://github.com/acmesh-official/acme.sh/wiki/dnsapi)

### Getting Help
- **Container Issues**: [Open an issue](https://github.com/nicat23/acme.sh-idracadm7/issues) in this repository
- **ACME.sh Core Issues**: [ACME.sh GitHub Issues](https://github.com/acmesh-official/acme.sh/issues)
- **Dell iDRAC Support**: Dell's official support channels

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for:
- Bug fixes and improvements
- Additional deploy hooks
- Documentation enhancements
- Feature requests

## 📄 License & Attribution

This project builds upon the excellent work of:
- **ACME.sh**: [acmesh-official/acme.sh](https://github.com/acmesh-official/acme.sh) by Neil Pang and contributors
- **iDRAC Deploy Hook**: Inspired by [societa-astronomica-g-v-schiaparelli/acme-idrac7](https://github.com/societa-astronomica-g-v-schiaparelli/acme-idrac7)
- **Deployment Scripts**: Concepts from [kroy-the-rabbit/acme_idrac_deployment](https://github.com/kroy-the-rabbit/acme_idrac_deployment)

This Docker image is provided as-is under the same license as the underlying ACME.sh project. Please refer to the [ACME.sh license](https://github.com/acmesh-official/acme.sh/blob/master/LICENSE.md) for details.

---

## 🏷️ Version History

### v2.0.0 (Current)
- Enhanced security hardening
- Improved iDRAC deploy hook with better error handling
- Multi-architecture support (amd64/arm64)
- Production-ready logging and monitoring
- Streamlined configuration management
- Comprehensive documentation

### v1.x
- Initial release with basic ACME.sh and iDRAC integration

---

*Built with ❤️ for enterprise SSL automation*