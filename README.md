# ACME.sh with Dell iDRAC Support

A containerized version of the popular [acme.sh](https://github.com/acmesh-official/acme.sh) SSL certificate management tool with integrated Dell iDRAC support for enterprise server environments.

This Docker image combines the power of acme.sh - a pure Unix shell script implementing the ACME client protocol - with Dell iDRAC management capabilities and a flexible initialization system that supports custom scripts while maintaining access to all default functionality.

## 🚀 Features

- ✅ **Full ACME.sh functionality** for Let's Encrypt and other ACME CAs
- ✅ **Dell iDRAC integration** via `racadm` command
- ✅ **Smart initialization system** with custom script support
- ✅ **Automated iDRAC certificate deployment** with included `idrac.sh` deploy hook
- ✅ **Flexible directory structure** supporting custom and default files
- ✅ **Support for multiple DNS providers** and deployment hooks
- ✅ **Automatic certificate renewal** via cron
- ✅ **Test scaffolding** for development and CI/CD
- ✅ **Docker Compose ready** with comprehensive examples
- ✅ **Based on Alpine Linux** for minimal footprint

## 🏗️ Architecture

The container uses a smart initialization system that:

1. **Installs acme.sh to `/defaults`** - Contains all original scripts and plugins
2. **Creates working directory at `/hooks`** - Where you mount your custom files  
3. **Symlinks missing files** - Ensures you have access to both custom and default files
4. **Preserves user files** - Never overwrites your custom scripts

### Directory Structure

```text
Container Paths:
├── /defaults/          # Original acme.sh installation (read-only)
│   ├── acme.sh         # Main acme.sh script
│   ├── deploy/         # Default deploy hooks
│   ├── dnsapi/         # Default DNS API scripts  
│   └── notify/         # Default notification scripts
├── /hooks/             # Working directory (your mounts)
│   ├── acme.sh         # Symlinked from defaults
│   ├── deploy/         # Your custom + default deploy hooks
│   ├── dnsapi/         # Your custom + default DNS APIs
│   └── notify/         # Your custom + default notifications
├── /config/            # Account configuration
└── /certs/             # Generated certificates
```

### Basic Certificate Issuance

```bash
# Issue a certificate with standalone method
docker run --rm -v "$(pwd)/acme.sh:/acme.sh" \
  nicat23/idracadm7:v1 \
  --issue -d example.com --standalone
```

### iDRAC Certificate Deployment

Use the included `idrac.sh` deploy hook for streamlined certificate deployment:

```bash
# Set environment variables for iDRAC connection
export DEPLOY_IDRAC_HOST="192.168.1.100"
export DEPLOY_IDRAC_USER="root"  
export DEPLOY_IDRAC_PASS="password"

# Issue and automatically deploy certificate to iDRAC
docker run --rm \
  -v "$(pwd)/acme.sh:/acme.sh" \
  -e DEPLOY_IDRAC_HOST \
  -e DEPLOY_IDRAC_USER \
  -e DEPLOY_IDRAC_PASS \
  -e CF_Token="your-cloudflare-token" \
  nicat23/idracadm7:v1 \
  --issue --dns dns_cf -d "idrac.example.com" --deploy-hook idrac.sh
```

### Daemon Mode

```bash
# Run as daemon for automatic renewals
docker run -d --name acme-daemon \
  -v "$(pwd)/acme.sh:/acme.sh" \
  nicat23/idracadm7:v1 daemon
```

## 🐋 Docker Compose Setup

Create the following directory structure:

```bash
<<<<<<< HEAD
mkdir -p certs config hooks/deploy hooks/dnsapi hooks/notify
=======
mkdir -p certs config deploy dnsapi notify
>>>>>>> 27db44c1 (Update readme)
```

### docker-compose.yml
mkdir -p certs config deploy dnsapi notify
### docker-compose.yml
### Usage Examples

```bash
# Start the container
docker-compose up -d

# Issue a certificate
docker-compose exec acme-sh acme.sh --issue -d example.com --dns dns_cf

# Deploy a certificate to iDRAC
docker-compose exec acme-sh acme.sh --deploy -d example.com --deploy-hook idrac.sh

# List certificates
docker-compose exec acme-sh --list

# Renew all certificates
docker-compose exec acme-sh --renew-all

# View logs
docker-compose logs -f acme-sh
```

## 🔧 Volume Mounts

| Host Path | Container Path | Purpose |
|-----------|---------------|---------|
| `./deploy` | `/hooks/deploy` | Custom deploy hooks |
| `./dnsapi` | `/hooks/dnsapi` | Custom DNS API scripts |
| `./notify` | `/hooks/notify` | Custom notification scripts |
| `./config` | `/config` | Account configuration |
| `./certs` | `/certs` | Certificate output |

## 📝 Custom Scripts

### Deploy Hooks

<<<<<<< HEAD
Place custom deploy hooks in `./hooks/deploy/`:

```bash
| Host Path | Container Path | Purpose |
|-----------|---------------|---------|
| `./deploy` | `/hooks/deploy` | Custom deploy hooks |
| `./dnsapi` | `/hooks/dnsapi` | Custom DNS API scripts |
| `./notify` | `/hooks/notify` | Custom notification scripts |
| `./config` | `/config` | Account configuration |
| `./certs` | `/certs` | Certificate output |
    _ccert="$3"
    _cca="$4"
    _cfullchain="$5"
    
    # Your custom deployment logic here
    echo "Deploying certificate for $_cdomain"
    
    return $?
}
```

Place custom deploy hooks in `./deploy/`:
<<<<<<< HEAD
Place custom DNS scripts in `./hooks/dnsapi/`:

```bash
#!/usr/bin/env sh
# hooks/dnsapi/dns_custom.sh
=======
Place custom DNS scripts in `./dnsapi/`:

```bash
#!/usr/bin/env sh
# dnsapi/dns_custom.sh
>>>>>>> 27db44c1 (Update readme)

dns_custom_add() {
    fulldomain=$1
## 🔧 Volume Mounts

| Host Path        | Container Path      | Purpose                  |
|------------------|--------------------|--------------------------|
| `./deploy`       | `/hooks/deploy`    | Custom deploy hooks      |
| `./dnsapi`       | `/hooks/dnsapi`    | Custom DNS API scripts   |
| `./notify`       | `/hooks/notify`    | Custom notification scripts |
| `./config`       | `/config`          | Account configuration    |
| `./certs`        | `/certs`           | Certificate output       |

| Variable | Default | Description |
|----------|---------|-------------|
| `LE_CONFIG_HOME` | `/config` | Account configuration directory |
| `LE_CERT_HOME` | `/certs` | Certificate output directory |
<<<<<<< HEAD
| `LE_BASE` | `/acme` | Working directory |
=======
| `LE_BASE` | `/hooks` | Working directory |
### Deploy Hooks

Place custom deploy hooks in `./deploy/`:
| `DRYRUN` | `false` | Enable dry-run mode (testing) |
| `DEPLOY_IDRAC_HOST` | - | iDRAC IP address or hostname |
| `DEPLOY_IDRAC_USER` | - | iDRAC username |
| `DEPLOY_IDRAC_PASS` | - | iDRAC password |

## 🧪 Testing

The container includes comprehensive test scaffolding for development and CI/CD:

### Debug Mode

Enable debug output during initialization:

```bash
docker run --rm -e DBG=true nicat23/idracadm7:v1 --help
```

### Dry Run Mode
| Variable | Default | Description |
|----------|---------|-------------|
| `LE_CONFIG_HOME` | `/config` | Account configuration directory |
| `LE_CERT_HOME` | `/certs` | Certificate output directory |
| `LE_BASE` | `/hooks` | Working directory |
| `LE_WORKING_DIR` | `/defaults` | Original installation directory |
| `AUTO_UPGRADE` | `1` | Enable automatic acme.sh upgrades |
| `DBG` | `false` | Enable debug output during initialization |
| `DRYRUN` | `false` | Enable dry-run mode (testing) |
| `DEPLOY_IDRAC_HOST` | - | iDRAC IP address or hostname |
| `DEPLOY_IDRAC_USER` | - | iDRAC username |
| `DEPLOY_IDRAC_PASS` | - | iDRAC password |
>>>>>>> 27db44c1 (Update readme)
```

### Monitor Container

View container logs:

```bash
docker logs -f acme-sh
```

## 💡 Advanced Usage

### Direct racadm Commands

```bash
# Check iDRAC status
docker run --rm nicat23/idracadm7:v1 \
  racadm -r 192.168.1.100 -u root -p password getconfig -g cfgRacTuning

# Upload SSL certificate directly
docker run --rm -v "$(pwd)/certs:/certs" \
  nicat23/idracadm7:v1 \
  racadm -r 192.168.1.100 -u root -p password \
| Variable           | Default      | Description                          |
|--------------------|-------------|--------------------------------------|
| `LE_CONFIG_HOME`   | `/config`   | Account configuration directory      |
| `LE_CERT_HOME`     | `/certs`    | Certificate output directory         |
| `LE_BASE`          | `/hooks`    | Working directory                    |
| `LE_WORKING_DIR`   | `/defaults` | Original installation directory      |
| `AUTO_UPGRADE`     | `1`         | Enable automatic acme.sh upgrades    |
| `DBG`              | `false`     | Enable debug output during initialization |
| `DRYRUN`           | `false`     | Enable dry-run mode (testing)        |
| `DEPLOY_IDRAC_HOST`| -           | iDRAC IP address or hostname         |
| `DEPLOY_IDRAC_USER`| -           | iDRAC username                       |
| `DEPLOY_IDRAC_PASS`| -           | iDRAC password                       |
# 4. Reset iDRAC to apply new certificate
docker-compose exec acme-sh \
  racadm -r idrac.example.com -u root -p password racreset soft
```

### Automation Example

```bash
#!/bin/bash
# Automated certificate renewal and deployment script

docker-compose exec acme-sh acme.sh --renew-all --force

# Process renewed certificates
for cert in certs/*/; do
    domain=$(basename "$cert")
    echo "Processing renewed certificate for $domain"
### Dry Run Mode
- Designed for enterprise Linux environments

### Recommended Security Measures

```bash
# Run with limited capabilities (test compatibility first)
docker run --rm --cap-drop=ALL --cap-add=DAC_OVERRIDE --cap-add=SETUID --cap-add=SETGID \
  -v "$(pwd)/acme.sh:/acme.sh" \
  nicat23/idracadm7:v1 --list

# Use read-only root filesystem where possible
docker run --rm --read-only --tmpfs /tmp --tmpfs /var/tmp \
  -v "$(pwd)/acme.sh:/acme.sh" \
  nicat23/idracadm7:v1 --list
```

### Best Practices

- **Use Linux x86_64 systems only** for Dell iDRAC functionality
- Run this container only in trusted enterprise environments
- **Not recommended for development on macOS** - use Linux VMs instead
- Use Docker's security features (user namespaces, seccomp profiles)
- Limit network access to only required services
- Monitor container activities through logging
- Consider running in isolated networks
- Store sensitive credentials securely (use Docker secrets in Swarm mode)

## 🔧 Troubleshooting

### Permission Issues

```bash
# Ensure proper directory permissions
<<<<<<< HEAD
mkdir -p ./certs ./config ./hooks/deploy ./hooks/dnsapi ./hooks/notify
chmod 755 ./certs ./config ./hooks ./hooks/deploy ./hooks/dnsapi ./hooks/notify
=======
mkdir -p ./certs ./config ./deploy ./dnsapi ./notify
chmod 755 ./certs ./config ./deploy ./dnsapi ./notify
>>>>>>> 27db44c1 (Update readme)

# SELinux considerations
chcon -Rt svirt_sandbox_file_t ./certs ./config
```

### iDRAC Connection Issues

1. Verify network connectivity to iDRAC
2. Check iDRAC credentials and permissions
3. Ensure iDRAC firmware supports certificate operations
4. Verify iDRAC web interface accessibility

### Container Debugging

```bash
# Interactive shell for debugging (Linux x86_64 only)
docker run --rm -it \
  -v "$(pwd)/certs:/certs" \
  -v "$(pwd)/config:/config" \
  nicat23/idracadm7:v1 sh

# Check container logs
docker-compose logs acme-sh

# Verify symlink structure
<<<<<<< HEAD
docker-compose exec acme-sh find /acme -type l -ls
=======
docker-compose exec acme-sh find /hooks -type l -ls
>>>>>>> 27db44c1 (Update readme)
```
mkdir -p ./certs ./config ./deploy ./dnsapi ./notify
chmod 755 ./certs ./config ./deploy ./dnsapi ./notify

**On ARM64 systems**:
- Dell Server Administrator tools are **not available** for ARM architecture
- Container will fail to start or racadm commands will not work
- Use x86_64 Linux systems for Dell iDRAC functionality

## 🏗️ Platform Support
⚠️ **Important**:

- This container requires **root privileges** for full functionality

- **Linux x86_64 only** - Dell racadm tools not available on ARM64 or untested on macOS

- Designed for enterprise Linux environments
- ❌ `darwin/arm64` (Apple Silicon Mac) - **Untested**

**Note**: This container is designed for Linux x86_64 systems. The Dell Server Administrator tools (`racadm`) required for iDRAC functionality are only available for x86_64 architecture.

## 📚 Migration Guide

### From Existing acme.sh Installation

If you have an existing acme.sh setup, you can migrate easily:

```bash
# Copy existing configuration and certificates
cp -r /path/to/existing/acme.sh/* ./config/
cp -r /path/to/existing/certs/* ./certs/

# Start using the container
docker-compose up -d
```

docker-compose exec acme-sh find /hooks -type l -ls

## 🤝 Contributing

Issues and pull requests are welcome! For major changes:

1. **acme.sh core functionality**: Contribute to the [upstream project](https://github.com/acmesh-official/acme.sh)
2. **Container-specific features**: Open an issue or PR in this repository
3. **iDRAC integration**: Feel free to improve the deploy hooks and documentation

## 📄 License

This Docker image is provided as-is. Please refer to the original [acme.sh license](https://github.com/acmesh-official/acme.sh/blob/master/LICENSE.md) for the underlying ACME client.

## 🙏 Acknowledgments

- **Original ACME.sh Project**: [acmesh-official/acme.sh](https://github.com/acmesh-official/acme.sh) - Neil Pang and contributors
- **Dell iDRAC Integration**: Dell Server Administrator tools
- **iDRAC Deploy Hook Inspiration**: 
  - [societa-astronomica-g-v-schiaparelli/acme-idrac7](https://github.com/societa-astronomica-g-v-schiaparelli/acme-idrac7)
  - [kroy-the-rabbit/acme_idrac_deployment](https://github.com/kroy-the-rabbit/acme_idrac_deployment)

## 📞 Support

- **acme.sh specific issues**: [acme.sh GitHub Issues](https://github.com/acmesh-official/acme.sh/issues)
- **Dell iDRAC questions**: Dell's official documentation
- **Docker image issues**: [Open an issue](https://github.com/nicat23/acme.sh-idracadm7/issues) in this repository- **iDRAC Deploy Hook Inspiration**:
  - [societa-astronomica-g-v-schiaparelli/acme-idrac7](https://github.com/societa-astronomica-g-v-schiaparelli/acme-idrac7)
  - [kroy-the-rabbit/acme_idrac_deployment](https://github.com/kroy-the-rabbit/acme_idrac_deployment)

## 📞 Support

- **acme.sh specific issues**: [acme.sh GitHub Issues](https://github.com/acmesh-official/acme.sh/issues)
- **Dell iDRAC questions**: Dell's official documentation
- **Docker image issues**: [Open an issue](https://github.com/nicat23/acme.sh-idracadm7/issues) in this repository