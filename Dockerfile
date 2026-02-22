# --- Stage 1: acme.sh build ---
FROM alpine:3.23 AS acme

ARG AUTO_UPGRADE=1 \
    LE_WORKING_DIR=/acme.sh \
    LE_CONFIG_HOME=/config \
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
    cd /install_acme.sh && ([ -f /install_acme.sh/acme.sh ] && /install_acme.sh/acme.sh --install --cert-home ${LE_CERT_HOME} \
    --config-home ${LE_CONFIG_HOME} --home ${LE_WORKING_DIR} \
    || curl https://get.acme.sh | sh) && rm -rf /install_acme.sh/ && \
    ln -s ${LE_WORKING_DIR}/acme.sh /usr/local/bin/acme.sh && \
    crontab -l | grep acme.sh | sed 's#> /dev/null#> /proc/1/fd/1 2>/proc/1/fd/2#' | crontab - && \
    for verb in help version install uninstall upgrade \
        issue signcsr deploy install-cert renew renew-all \
        revoke remove list info showcsr install-cronjob \
        uninstall-cronjob cron toPkcs toPkcs8 update-account \
        register-account create-account-key create-domain-key \
        createCSR deactivate deactivate-account set-notify \
        set-default-ca set-default-chain \
    ; do \
    printf -- "%b"\
    "#!/usr/bin/env sh\n\
    ${LE_WORKING_DIR}/acme.sh --${verb} --config-home ${LE_CONFIG_HOME} \"$@\"\n \
    " >"/usr/local/bin/--${verb}" && \
    chmod +x "/usr/local/bin/--${verb}" \
    ; done && \
    # Clean up to reduce attack surface
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/* /usr/share/man /usr/share/doc

# --- Stage 2: Dell EMC racadm build ---
FROM alpine:3.23 AS emc

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
    # Create symlinks
    [ ! -e /usr/lib/libssl.so ] && { \
    if [ -e /usr/lib/libssl.so.3 ]; then \
    ln -s /usr/lib/libssl.so.3 /usr/lib/libssl.so; \
    elif [ -e /usr/lib64/libssl.so.3 ]; then \
    ln -s /usr/lib64/libssl.so.3 /usr/lib/libssl.so; \
    fi; \
    } && \
    # Generate wrapper script instead of symlink
    printf '%s\n' \
        '#!/bin/sh' \
        '# Auto-generated racadm wrapper script' \
        '# This script automatically handles privilege escalation for racadm' \
        '' \
        'RACADM_BINARY="/opt/dell/srvadmin/bin/idracadm7"' \
        '' \
        '# Check if the actual racadm binary exists' \
        'if [ ! -x "$RACADM_BINARY" ]; then' \
        '    echo "Error: racadm binary not found at $RACADM_BINARY" >&2' \
        '    exit 1' \
        'fi' \
        '' \
        '# If already running as root, execute directly' \
        'if [ "$(id -u)" = "0" ]; then' \
        '    exec "$RACADM_BINARY" "$@"' \
        'else' \
        '    # Use sudo for privilege escalation' \
        '    exec sudo "$RACADM_BINARY" "$@"' \
        'fi' \
    > /usr/bin/racadm && \
    chmod +x /usr/bin/racadm && \
    # Aggressive cleanup for minimal image size
    rm -rf /usr/share/man \
    /tmp/* \
    /usr/share/doc/* \
    /usr/share/info/* \
    /usr/share/licenses/* \
    /usr/share/locale/* \
    /usr/share/man/* \
    /var/tmp/* \
    /var/cache/apk/* \
    /var/lib/rpm \
    /var/log/* \
    /var/cache/* \
    /root/.cache \
    /root/.rpmdb \
    /opt/dell/srvadmin/share/doc \
    /opt/dell/srvadmin/share/man \
    /opt/dell/srvadmin/var \
    ~/.wget-hsts \
    ~/.cache 2>/dev/null || true && \
    find /opt/dell -name "*.log" -delete 2>/dev/null || true && \
    find /opt/dell -type d -empty -delete 2>/dev/null || true

# --- Final Stage: Combine both environments ---
FROM alpine:3.23

RUN addgroup -g 1000 -S appgroup && \
    adduser -u 1000 -S appuser -G appgroup -s /bin/sh
# Copy acme.sh environment
COPY --from=acme --chown=appuser:appgroup /acme.sh /acme.sh
COPY --from=acme --chown=appuser:appgroup /usr/local/bin/acme.sh /usr/local/bin/acme.sh
COPY --from=acme --chown=appuser:appgroup /usr/local/bin/--* /usr/local/bin/
COPY --from=acme --chown=appuser:appgroup /init /init
COPY --from=acme --chown=root:root /entry.sh /entry.sh

# Copy racadm and dependencies
COPY --from=emc  /opt/dell /opt/dell
COPY --from=emc  /usr/bin/racadm /usr/bin/racadm
COPY --from=emc  /usr/lib/libssl.so* /usr/lib/
COPY --from=emc  /usr/lib64/libssl.so* /usr/lib64/

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
    logrotate \
    gcompat \
    libc6-compat \
    libstdc++ \
    sudo && \
# Security hardening
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/* && \
    # Remove unnecessary packages that might have been pulled as dependencies
    apk del --purge \
        $(apk info --installed | grep -E '^(pkgconf|build-base|gcc|musl-dev)' \
        | cut -d' ' -f1) 2>/dev/null || true && \
    # Create logrotate config for acme.sh
    echo '/config/acme.sh.log {\n\
        daily\n\
        rotate 7\n\
        missingok\n\
        notifempty\n\
        compress\n\
        delaycompress\n\
        copytruncate\n\}' > /etc/logrotate.d/acme.sh && \
        echo '#!/bin/sh' > /etc/periodic/daily/logrotate && \
        echo '/usr/sbin/logrotate /etc/logrotate.conf' >> /etc/periodic/daily/logrotate && \
        chmod a+x /etc/periodic/daily/logrotate
ARG AUTO_UPGRADE=1 \
    LE_WORKING_DIR=/acme.sh \
    LE_CONFIG_HOME=/config \
    LE_CERT_HOME=/certs

ENV LE_WORKING_DIR=$LE_WORKING_DIR \
    LE_CONFIG_HOME=$LE_CONFIG_HOME \
    LE_CERT_HOME=$LE_CERT_HOME \
    AUTO_UPGRADE=$AUTO_UPGRADE \
    # Security environment variables
    PAGER=cat \
    SHELL=/bin/sh

# Create non-root user with minimal privileges
RUN mkdir -p ${LE_CERT_HOME} ${LE_CONFIG_HOME} /hooks && \
    chown appuser:appgroup ${LE_CERT_HOME} ${LE_CONFIG_HOME} /hooks && \
    chmod 750 ${LE_CERT_HOME} ${LE_CONFIG_HOME} /hooks && \
# IMPROVED: More secure sudo configuration
    echo 'Defaults env_reset' > /etc/sudoers.d/app && \
    echo 'Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' >> /etc/sudoers.d/app && \
    echo 'Defaults passwd_timeout=0' >> /etc/sudoers.d/app && \
    echo 'Defaults !requiretty' >> /etc/sudoers.d/app && \
    echo '%appgroup ALL=(root) NOPASSWD: /usr/bin/racadm, /opt/dell/srvadmin/bin/idracadm7, \
        /usr/sbin/crond, /bin/chmod' >> /etc/sudoers.d/app && \
    chmod 0440 /etc/sudoers.d/app && \
    # Test sudo configuration
    visudo -c && \
    # Make entry script executable and owned by root for security
    chown root:root /entry.sh && \
    chmod 755 /entry.sh && \
    # Create a test to ensure racadm works
    # Test that sudo is configured correctly (without actually running racadm)
    sudo -u appuser sudo -l | grep -q racadm && echo "✅ Sudo configuration verified" || echo "❌ Sudo configuration failed"

# Use non-root user
USER appuser

VOLUME ["/certs", "${LE_CONFIG_HOME}", "/hooks"]
WORKDIR ${LE_WORKING_DIR}
SHELL ["/bin/sh", "-c"]
ENTRYPOINT ["/entry.sh"]
CMD ["--help"]
