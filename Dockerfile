FROM alpine:3.22

# Install required packages
RUN apk --no-cache add -f \
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
  libstdc++

# Environment variables
ENV LE_CONFIG_HOME=/config \
    LE_WORKING_DIR=/defaults \
    LE_CERT_HOME=/certs \
    LE_BASE=/acme \
    AUTO_UPGRADE=1 \
    ACME_DEBUG=false \
    ACME_DRY_RUN=false

# Create volume mount directories
RUN mkdir -p /certs /config \
    && mkdir -p /acme/deploy /acme/dnsapi /acme/notify \
    && mkdir -p /mnt/deploy /mnt/dnsapi /mnt/notify \
    && mkdir -p /init.d /defaults

# Copy init scripts and defaults
COPY ./init.d/ /init.d/
COPY ./defaults/ /defaults/
RUN chmod +x /init.d/*.sh

# Install Dell iDRAC software
RUN apk --no-cache add rpm && \
  rpm -ivh --nodeps --force \
    https://linux.dell.com/repo/hardware/DSU_24.11.11/os_dependent/RHEL9_64/srvadmin/srvadmin-argtable2-11.0.0.0-5268.el9.x86_64.rpm \
    https://linux.dell.com/repo/hardware/DSU_24.11.11/os_dependent/RHEL9_64/srvadmin/srvadmin-hapi-11.0.0.0-5268.el9.x86_64.rpm \
    https://linux.dell.com/repo/hardware/DSU_24.11.11/os_dependent/RHEL9_64/srvadmin/srvadmin-idracadm7-11.0.0.0-5268.el9.x86_64.rpm && \
  apk del rpm jq && rm -rf /var/cache/apk/*

# Create SSL symlinks for Dell tools
RUN [ ! -e /usr/lib/libssl.so ] && { \
  [ -e /usr/lib/libssl.so.3 ] && ln -s /usr/lib/libssl.so.3 /usr/lib/libssl.so || \
  { [ -e /usr/lib64/libssl.so.3 ] && ln -s /usr/lib64/libssl.so.3 /usr/lib/libssl.so; }; \
}

# Create racadm symlink
RUN ln -s /opt/dell/srvadmin/bin/idracadm7 /usr/bin/racadm

# Install acme.sh
COPY ./acme.sh /install_acme.sh/acme.sh
COPY ./deploy /install_acme.sh/deploy
COPY ./dnsapi /install_acme.sh/dnsapi
COPY ./notify /install_acme.sh/notify

RUN set -eux; \
  echo "🚀 Starting acme.sh install to ${LE_WORKING_DIR}..."; \
  if [ "${ACME_DRY_RUN:-false}" = "true" ]; then \
    echo "🧪 Dry-run mode: skipping acme.sh install"; \
  else \
    cd /install_acme.sh && chmod +x acme.sh; \
    if [ "${ACME_DEBUG:-false}" = "true" ]; then \
      echo "🔧 Running local acme.sh install with debug output..."; \
      ./acme.sh --install \
        --home "${LE_WORKING_DIR}" \
        --config-home "${LE_CONFIG_HOME}" \
        --cert-home "${LE_CERT_HOME}" \
        --debug \
      || { \
        echo "⚠️ Local install failed, falling back to curl..."; \
        curl -fsSL https://get.acme.sh | sh -s -- \
          --home "${LE_WORKING_DIR}" \
          --config-home "${LE_CONFIG_HOME}" \
          --cert-home "${LE_CERT_HOME}" \
          --debug; \
      }; \
    else \
      echo "🔧 Running local acme.sh install..."; \
      ./acme.sh --install \
        --home "${LE_WORKING_DIR}" \
        --config-home "${LE_CONFIG_HOME}" \
        --cert-home "${LE_CERT_HOME}" \
      || { \
        echo "⚠️ Local install failed, falling back to curl..."; \
        curl -fsSL https://get.acme.sh | sh -s -- \
          --home "${LE_WORKING_DIR}" \
          --config-home "${LE_CONFIG_HOME}" \
          --cert-home "${LE_CERT_HOME}"; \
      }; \
    fi; \
    rm -rf /install_acme.sh; \
    echo "✅ acme.sh install complete to ${LE_WORKING_DIR}"; \
  fi

# Create helper commands for acme.sh verbs
RUN for verb in help version install uninstall upgrade issue signcsr deploy \
  install-cert renew renew-all revoke remove list info showcsr \
  install-cronjob uninstall-cronjob cron toPkcs toPkcs8 update-account \
  register-account create-account-key create-domain-key createCSR \
  deactivate deactivate-account set-notify set-default-ca set-default-chain; do \
    printf '#!/usr/bin/env sh\nexec %s/acme.sh --%s --config-home %s "$@"\n' \
      "${LE_WORKING_DIR}" "${verb}" "${LE_CONFIG_HOME}" > "/usr/local/bin/--${verb}"; \
    chmod +x "/usr/local/bin/--${verb}"; \
  done

# Entrypoint with modular init
RUN printf '#!/usr/bin/env sh\n\
echo "🚀 Running container initialization..."\n\
for f in /init.d/*.sh; do\n\
  echo "🔧 Executing $f..."\n\
  bash "$f"\n\
done\n\
if [ "$1" = "daemon" ]; then\n\
  echo "🔄 Starting cron daemon..."\n\
  exec crond -n -s -m off\n\
else\n\
  exec -- "$@"\n\
fi\n' > /entry.sh && chmod +x /entry.sh

# Define volumes
VOLUME ["/certs", "/config", "/acme/deploy", "/acme/dnsapi", "/acme/notify"]

ENTRYPOINT ["/entry.sh"]
CMD ["--help"]
