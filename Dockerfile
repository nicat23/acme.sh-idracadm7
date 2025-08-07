FROM alpine:3.22

# Install required packages
RUN apk --no-cache add \
  openssl \
  openssh-client \
  coreutils \
  bash \
  bind-tools \
  curl \
  sed \
  socat \
  tzdata \
  oath-toolkit-oathtool \
  tar \
  libidn \
  jq \
  cronie \
  gcompat \
  libc6-compat \
  libstdc++ \
  rpm

# Environment variables
ENV LE_CONFIG_HOME=/config \
    LE_WORKING_DIR=/defaults \
    LE_CERT_HOME=/certs \
    LE_BASE=/acme \
    AUTO_UPGRADE=1 \
    ACME_DEBUG=false \
    ACME_DRY_RUN=false \
    DRY_RUN=false \
    DEBUG=false

# Create volume mount directories
RUN mkdir -p /certs /config \
    && mkdir -p /acme/deploy /acme/dnsapi /acme/notify \
    && mkdir -p /mnt/deploy /mnt/dnsapi /mnt/notify \
    && mkdir -p /init.d /defaults

# Copy init scripts and defaults
COPY init.d/ /init.d/
RUN chmod +x /init.d/*.sh
COPY verify-overlay.sh /usr/local/bin/--verify-overlay
RUN chmod +x /usr/local/bin/--verify-overlay
COPY defaults/acme.sh /defaults/acme.sh
COPY defaults/deploy/   /defaults/deploy/
COPY defaults/dnsapi/   /defaults/dnsapi/
COPY defaults/notify/   /defaults/notify/

# Verify contents
RUN echo "📦 Verifying /defaults contents:" && ls -lR /defaults

# Install acme.sh
RUN set -eux; \
  echo "🚀 Installing acme.sh from /defaults/acme.sh into /acme..."; \
  chmod +x /defaults/acme.sh; \
  cd /defaults; \
  if [ "${ACME_DRY_RUN}" = "true" ]; then \
    echo "🧪 Dry-run mode: skipping acme.sh install"; \
  else \
    mkdir -p /acme; \
    if [ "${ACME_DEBUG}" = "true" ]; then \
      echo "🔧 Running acme.sh install with debug output..."; \
      ./acme.sh --install \
        --home /acme \
        --config-home "${LE_CONFIG_HOME}" \
        --cert-home "${LE_CERT_HOME}" \
        --debug; \
    else \
      echo "🔧 Running acme.sh install..."; \
      ./acme.sh --install \
        --home /acme \
        --config-home "${LE_CONFIG_HOME}" \
        --cert-home "${LE_CERT_HOME}"; \
    fi; \
    echo "✅ acme.sh install complete to /acme"; \
  fi
RUN ln -s /acme/acme.sh /usr/local/bin/acme.sh && \
  (crontab -l 2>/dev/null | grep acme.sh | \
   sed 's#> /dev/null#> /proc/1/fd/1 2>/proc/1/fd/2#' | crontab - || true)

# Create helper commands for acme.sh verbs
RUN for verb in help version install uninstall upgrade issue signcsr deploy \
  install-cert renew renew-all revoke remove list info showcsr \
  install-cronjob uninstall-cronjob cron toPkcs toPkcs8 update-account \
  register-account create-account-key create-domain-key createCSR \
  deactivate deactivate-account set-notify set-default-ca set-default-chain; do \
    printf '#!/usr/bin/env sh\nexec /acme/acme.sh --%s --config-home %s "$@"\n' \
      "${verb}" "${LE_CONFIG_HOME}" > "/usr/local/bin/--${verb}"; \
    chmod +x "/usr/local/bin/--${verb}"; \
  done

# Install Dell iDRAC software
RUN rpm -ivh --nodeps --force \
    https://linux.dell.com/repo/hardware/DSU_24.11.11/os_dependent/RHEL9_64/srvadmin/srvadmin-argtable2-11.0.0.0-5268.el9.x86_64.rpm \
    https://linux.dell.com/repo/hardware/DSU_24.11.11/os_dependent/RHEL9_64/srvadmin/srvadmin-hapi-11.0.0.0-5268.el9.x86_64.rpm \
    https://linux.dell.com/repo/hardware/DSU_24.11.11/os_dependent/RHEL9_64/srvadmin/srvadmin-idracadm7-11.0.0.0-5268.el9.x86_64.rpm \
  && apk del rpm jq && rm -rf /var/cache/apk/*

# Create SSL symlinks for Dell tools
RUN [ ! -e /usr/lib/libssl.so ] && { \
  [ -e /usr/lib/libssl.so.3 ] && ln -s /usr/lib/libssl.so.3 /usr/lib/libssl.so || \
  { [ -e /usr/lib64/libssl.so.3 ] && ln -s /usr/lib64/libssl.so.3 /usr/lib/libssl.so; }; \
}

# Create racadm symlink
RUN ln -s /opt/dell/srvadmin/bin/idracadm7 /usr/bin/racadm
# Entrypoint with modular init and safe exec
RUN echo '#!/usr/bin/env sh' > /entry.sh && \
    echo 'echo "🚀 Running container initialization..."' >> /entry.sh && \
    echo '' >> /entry.sh && \
    echo 'for f in /init.d/*.sh; do' >> /entry.sh && \
    echo '  echo "🔧 Executing $f..."' >> /entry.sh && \
    echo '  bash "$f"' >> /entry.sh && \
    echo 'done' >> /entry.sh && \
    echo '' >> /entry.sh && \
    echo 'if [ "$#" -eq 0 ]; then' >> /entry.sh && \
    echo '  echo "ℹ️ No command provided. Showing help:"' >> /entry.sh && \
    echo '  exec /usr/local/bin/--help' >> /entry.sh && \
    echo 'else' >> /entry.sh && \
    echo '  echo "▶️ Executing: $@"' >> /entry.sh && \
    echo '  exec "$@"' >> /entry.sh && \
    echo 'fi' >> /entry.sh && \
    chmod +x /entry.sh


# Define volumes
VOLUME ["/certs", "/config", "/acme/deploy", "/acme/dnsapi", "/acme/notify"]

ENTRYPOINT ["/entry.sh"]
CMD []
