# ACME.sh with Dell iDRAC Support

A containerized version of the popular ACME.sh SSL certificate management tool with integrated Dell iDRAC support for enterprise server environments.

## About

This Docker image combines the power of [acme.sh](https://github.com/acmesh-official/acme.sh) - a pure Unix shell script implementing the ACME client protocol - with Dell iDRAC management capabilities. It's designed for enterprise environments where SSL certificates need to be automatically deployed to Dell servers via iDRAC.

## Credits

- **Original ACME.sh Project**: [acmesh-official/acme.sh](https://github.com/acmesh-official/acme.sh)
- **ACME.sh Author**: Neil Pang and contributors
- **Dell iDRAC Integration**: This image includes Dell Server Administrator tools for iDRAC management
- **iDRAC Deployment Hook Inspiration**: The included `idrac.sh` deploy hook was inspired by [societa-astronomica-g-v-schiaparelli/acme-idrac7](https://github.com/societa-astronomica-g-v-schiaparelli/acme-idrac7) and [kroy-the-rabbit/acme_idrac_deployment](https://github.com/kroy-the-rabbit/acme_idrac_deployment)

## Features

- ✅ Full ACME.sh functionality for Let's Encrypt and other ACME CAs
- ✅ Dell iDRAC integration via `racadm` command
- ✅ Automated iDRAC certificate deployment with included `idrac.sh` deploy hook
- ✅ Support for multiple DNS providers and deployment hooks
- ✅ Automatic certificate renewal via cron
- ✅ Custom deploy, DNS API, and notification scripts support
- ✅ Based on Alpine Linux for minimal footprint

## Quick Start

First, start the container in detached mode using Docker Compose:
```bash
docker compose up -d
```

### Basic Certificate Issuance
```bash
docker exec -t acme.sh --issue -d example.com --standalone
```

### Automated iDRAC Certificate Deployment with Deploy Hook

Use the included `idrac.sh` deploy hook for streamlined certificate deployment:

```bash
# Set environment variables for iDRAC connection
export DEPLOY_IDRAC_HOST="192.168.1.100"
export DEPLOY_IDRAC_USER="root"
export DEPLOY_IDRAC_PASS="password"

# Issue and automatically deploy certificate to iDRAC
docker exec -t acme.sh --issue --dns dns_cf -d "idrac.example.com" --deploy-hook idrac
```

Or deploy an existing certificate:

```bash
# Deploy existing certificate using the idrac.sh hook
docker exec -t acme.sh --deploy -d "idrac.example.com" --deploy-hook idrac
```

### Manual iDRAC Certificate Deployment
```bash
docker exec -t acme.sh racadm -r 192.168.1.100 -u root -p password sslcertupload -t 1 -f /certs/example.com/fullchain.cer
docker exec -t acme.sh racadm -r 192.168.1.100 -u root -p password sslkeyupload -t 1 -f /certs/example.com/example.com.key
docker exec -t acme.sh racadm -r 192.168.1.100 -u root -p password racreset
```

### Run as Daemon (with automatic renewals)
The `docker-compose.yml` example already runs the container as a daemon.

## Usage

### Available Commands

The container supports all standard acme.sh commands:

```bash
# Issue a certificate
docker exec -t acme.sh --issue -d example.com --dns dns_cloudflare

# Renew certificates
docker exec -t acme.sh --renew-all

# List certificates
docker exec -t acme.sh --list
```

### Dell iDRAC Management

Use the `racadm` command directly:

```bash
# Check iDRAC status
docker exec -t acme.sh racadm -r 192.168.1.100 -u root -p password getconfig -g cfgRacTuning

# Upload SSL certificate to iDRAC
docker exec -t acme.sh racadm -r 192.168.1.100 -u root -p password sslcertupload -t 1 -f /certs/example.com/fullchain.cer

# Reset the iDRAC to apply the new certificate
docker exec -t acme.sh racadm -r 192.168.1.100 -u root -p password racreset
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `LE_CONFIG_HOME` | `/acme.sh` | ACME.sh configuration directory. It is recommended to use `/config` for persistent storage. |
| `AUTO_UPGRADE` | `1` | Enable automatic acme.sh upgrades |
| `DEPLOY_IDRAC_HOST` | - | iDRAC IP address or hostname for deploy hook |
| `DEPLOY_IDRAC_USER` | - | iDRAC username for deploy hook |
| `DEPLOY_IDRAC_PASS` | - | iDRAC password for deploy hook |

## Configuration

This container is designed to be configured through volume mounts, allowing you to persist data and customize its behavior.

### Directory Structure

- `/acme.sh`: The installation directory for the `acme.sh` script itself.
- `/config`: Persistent storage for `acme.sh` configuration files. Your `account.conf` and other settings will be stored here.
- `/certs`:  The output directory for your generated SSL certificates.
- `/hooks`:  A directory for your custom scripts. You can mount your own scripts here, which will be used by `acme.sh`.
    - `/hooks/deploy`: For custom deploy hooks.
    - `/hooks/dnsapi`: For custom DNS API handlers.
    - `/hooks/notify`: For custom notification scripts.

## Custom Script Structure

The image has been customized to support a more modular and extensible structure. This includes a custom `idrac.sh` deploy script, an `overlay.sh` for logic, and a separate `entry.sh` script.

The custom script structure within the project is as follows:

```
├─ hooks
│  ├─ deploy
│  │  └─ idrac.sh
│  ├─ dnsapi/
│  └─ notify/
├─ init
│  └─ overlay.sh
└─ entry.sh
```

- **`hooks/deploy/idrac.sh`**: The custom deployment hook for Dell iDRAC servers.
- **`init/overlay.sh`**: A script for overlaying custom logic or files at container startup.
- **`entry.sh`**: The main entrypoint script for the container.

## Usage Examples

First, start the container in detached mode:

```bash
docker compose up -d
```

Then, execute commands within the running container:

### Wildcard Certificate with PKCS12 Post-Hook

Issue a wildcard certificate and convert it to a PKCS12 file with a post-hook.

```bash
docker exec -t acme.sh --issue -d example.com -d *.example.com --dns dns_cf --post-hook "--toPkcs -d example.com --password PKCSPASSWORD"
```

### Issue and Deploy Certificate to iDRAC

Set the required environment variables for your iDRAC, then issue and deploy the certificate.

```bash
# Set environment variables for iDRAC connection
export DEPLOY_IDRAC_HOST="idrac-hostname"
export DEPLOY_IDRAC_USER="idrac-user"
export DEPLOY_IDRAC_PASS="idrac-password"

# Issue a certificate using a DNS provider (e.g., Cloudflare)
docker exec -t acme.sh --issue --dns dns_cf -d idrac-hostname

# Deploy the certificate to iDRAC using the custom deploy hook
docker exec -t acme.sh --deploy -d idrac-hostname --deploy-hook idrac
```

## Docker Compose Example

```yaml
services:
  acme-sh:
    image: nicat23/idracadm7:v4
    container_name: acme.sh
    volumes:
      - ./certs:/certs
      - ./hooks:/hooks
      - ./config:/config
    command: daemon
    stdin_open: true
    tty: true
    restart: always
    networks:
      - proxy
networks:
  proxy:
    external: true
```

## Building from Source

You can build the Docker image locally for development or customization purposes.

### Build Command

```bash
docker build -t nicat23/idracadm7 .
```

### Build-time Arguments

The `Dockerfile` supports several build-time arguments (`ARG`) to customize the image:

- `AUTO_UPGRADE`: Set to `1` to enable automatic upgrades of `acme.sh`, or `0` to disable.
- `LE_WORKING_DIR`: The working directory for `acme.sh`.
- `LE_CONFIG_HOME`: The directory for configuration files.
- `LE_CERT_HOME`: The directory for certificates.

You can customize these during the build process. For example:

```bash
docker build --build-arg AUTO_UPGRADE=0 -t nicat23/idracadm7 .
```

These arguments are then set as environment variables (`ENV`) within the image.

### Volume Mounts

The volume mount points for configuration, certificates, and hooks can be customized in your `docker-compose.yml` or `docker run` commands to suit your environment.

### Script Logic

The container uses `entry.sh` as its main entrypoint, which in turn can execute `overlay.sh` for initialization.

#### `entry.sh`

The `entry.sh` script is the primary script that runs when the container starts. Its logic is as follows:

1.  **Initialization Check**: It checks if essential configuration files (`account.conf`, `http.header`) exist in the `/config` directory. If not, it runs `acme.sh --upgrade` to create them.
2.  **Overlay Execution**: It looks for an `overlay.sh` script in the `/init` directory. If found, it executes it, which links any custom scripts from the `/hooks` volume into their respective directories in `/acme.sh`.
3.  **Command Execution**: It inspects the command passed to the container:
    - If the command is `daemon`, it starts the cron daemon to handle automated renewals.
    - If the command is `racadm`, it executes Dell's `racadm` utility with the provided arguments.
    - Otherwise, it executes the command as-is, which is typically an `acme.sh` command.

#### `overlay.sh`

The `overlay.sh` script is responsible for integrating custom user scripts into the `acme.sh` environment. It works as follows:

1.  **Scan for Hooks**: It scans the `/hooks` directory for subdirectories named `deploy`, `dnsapi`, and `notify`.
2.  **Link Scripts**: If any of these directories are found, it iterates through the `.sh` files within them and creates symbolic links from your custom scripts to the corresponding `acme.sh` script directories (e.g., from `/hooks/deploy/my-hook.sh` to `/acme.sh/deploy/my-hook.sh`).

This allows you to easily add and manage your own custom hooks by mounting them into the `/hooks` volume.

## Supported Platforms

- **`linux/amd64`**: Supported and tested. The container is built for this platform.
- **`windows`**: Tested. The container can be run on Windows with a compatible Docker environment.
- **`macOS`**: Untested.
- **`linux/arm64`**: Not supported. The Dell iDRAC tools (`racadm`) require an x86 architecture and will not run on ARM-based systems.

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
