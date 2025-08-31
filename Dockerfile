# --- Stage 1: acme.sh build ---
FROM alpine:3.22 AS acme

# Use latest Alpine 3.23 which has fixes for many CVEs
ARG AUTO_UPGRADE=1 \
  LE_WORKING_DIR=/acme.sh \
  LE_CONFIG_HOME=$LE_WORKING_DIR/config \
  LE_CERT_HOME=/certs

ENV LE_WORKING_DIR=$LE_WORKING_DIR \
  LE_CONFIG_HOME=$LE_CONFIG_HOME \
  LE_CERT_HOME=$LE_CERT_HOME \
  AUTO_UPGRADE=$AUTO_UPGRADE

COPY ./acme.sh /install_acme.sh/acme.sh
COPY ./deploy /install_acme.sh/deploy
COPY ./dnsapi /install_acme.sh/dnsapi
COPY ./notify /install_acme.sh/notify
COPY ./init/ /init/
COPY ./entry.sh /entry.sh

# Update packages to latest versions and install security updates
RUN apk update && apk upgrade && \
    apk --no-cache add -f \
    openssl \
    openssh-client \
    coreutils \
    bind-tools \
    curl \
    sed \
    socat \
    tzdata \
    oath-toolkit-oathtool \
    tar \
    libidn \
    jq \
    cronie && \
    cd /install_acme.sh && ([ -f /install_acme.sh/acme.sh ] && /install_acme.sh/acme.sh --install \
    --cert-home ${LE_CERT_HOME} --config-home ${LE_CONFIG_HOME} --home ${LE_WORKING_DIR} --debug \
    || curl https://get.acme.sh | sh) && rm -rf /install_acme.sh/ && \
    ln -s ${LE_WORKING_DIR}/acme.sh /usr/local/bin/acme.sh && \
    crontab -l | grep acme.sh | sed 's#> /dev/null#> /proc/1/fd/1 2>/proc/1/fd/2#' | crontab - && \
    for verb in help \
    version \
    install \
    uninstall \
    upgrade \
    issue \
    signcsr \
    deploy \
    install-cert \
    renew \
    renew-all \
    revoke \
    remove \
    list \
    info \
    showcsr \
    install-cronjob \
    uninstall-cronjob \
    cron \
    toPkcs \
    toPkcs8 \
    update-account \
    register-account \
    create-account-key \
    create-domain-key \
    createCSR \
    deactivate \
    deactivate-account \
    set-notify \
    set-default-ca \
    set-default-chain \
    ; do \
        printf -- "%b"\
"#!/usr/bin/env sh\n\
${LE_WORKING_DIR}/acme.sh --${verb} --config-home ${LE_CONFIG_HOME} \"\$@\"\n\
" >"/usr/local/bin/--${verb}" && \
        chmod +x "/usr/local/bin/--${verb}" \
    ; done && \
    # Clean up to reduce attack surface
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

# --- Stage 2: Dell EMC racadm build ---
FROM alpine:3.22 AS emc

# Update packages and install security updates
RUN apk update && apk upgrade && \
    apk --no-cache add \
    curl \
    gcompat \
    libc6-compat \
    libstdc++ \
    rpm && \
    rpm -ivh --nodeps --force \
    https://linux.dell.com/repo/hardware/DSU_24.11.11/os_dependent/RHEL9_64/srvadmin/srvadmin-argtable2-11.0.0.0-5268.el9.x86_64.rpm \
    https://linux.dell.com/repo/hardware/DSU_24.11.11/os_dependent/RHEL9_64/srvadmin/srvadmin-hapi-11.0.0.0-5268.el9.x86_64.rpm \
    https://linux.dell.com/repo/hardware/DSU_24.11.11/os_dependent/RHEL9_64/srvadmin/srvadmin-idracadm7-11.0.0.0-5268.el9.x86_64.rpm \
    && apk del rpm curl && \
    rm -rf /var/cache/apk/* /root/.rpmdb /tmp/* /var/tmp/* && \
    [ ! -e /usr/lib/libssl.so ] && { \
    if [ -e /usr/lib/libssl.so.3 ]; then \
    ln -s /usr/lib/libssl.so.3 /usr/lib/libssl.so; \
    elif [ -e /usr/lib64/libssl.so.3 ]; then \
    ln -s /usr/lib64/libssl.so.3 /usr/lib/libssl.so; \
    else \
    echo "ERROR: Could not find libssl.so.3 in /usr/lib or /usr/lib64. Dell tools may not work properly." >&2; \
    exit 1; \
    fi; \
    } && [ ! -e /usr/bin/racadm ] && \
    ln -s /opt/dell/srvadmin/bin/idracadm7 /usr/bin/racadm \
    || echo "/usr/bin/racadm already exists, not overwriting"

# --- Final Stage: Combine both environments ---
FROM alpine:3.22

# Copy acme.sh environment
COPY --from=acme /acme.sh /acme.sh
COPY --from=acme /usr/local/bin/acme.sh /usr/local/bin/acme.sh
COPY --from=acme /usr/local/bin/--* /usr/local/bin/
COPY --from=acme /init /init
COPY --from=acme /entry.sh /entry.sh

# Copy racadm and dependencies
COPY --from=emc /opt/dell /opt/dell
COPY --from=emc /usr/bin/racadm /usr/bin/racadm
COPY --from=emc /usr/lib/libssl.so* /usr/lib/
COPY --from=emc /usr/lib64/libssl.so* /usr/lib64/
COPY --from=emc /usr/lib/libstdc++* /usr/lib/
COPY --from=emc /usr/lib64/libstdc++* /usr/lib64/
COPY --from=emc /usr/lib/libc6-compat* /usr/lib/
COPY --from=emc /usr/lib64/libc6-compat* /usr/lib64/
COPY --from=emc /usr/lib/gcompat* /usr/lib/
COPY --from=emc /usr/lib64/gcompat* /usr/lib64/

# Install all required packages with latest versions and security updates
RUN apk update && apk upgrade && \
    apk --no-cache add \
    openssl \
    openssh-client \
    coreutils \
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
    libstdc++ && \
    # Clean up package cache and temporary files
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

ARG AUTO_UPGRADE=1 \
  LE_WORKING_DIR=/acme.sh \
  LE_CONFIG_HOME=$LE_WORKING_DIR/config \
  LE_CERT_HOME=/certs

ENV LE_WORKING_DIR=$LE_WORKING_DIR \
  LE_CONFIG_HOME=$LE_CONFIG_HOME \
  LE_CERT_HOME=$LE_CERT_HOME \
  AUTO_UPGRADE=$AUTO_UPGRADE

# Create non-root user for better security
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup && \
    chown -R appuser:appgroup /acme.sh /certs || true

VOLUME ["/certs", "${LE_WORKING_DIR}/config", "/hooks"]

# Use non-root user
USER appuser

SHELL ["/bin/sh", "-c"]
ENTRYPOINT ["/entry.sh"]
CMD ["--help"]
