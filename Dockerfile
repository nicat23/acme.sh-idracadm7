# --- Stage 1: acme.sh ---
FROM neilpang/acme.sh:latest AS acme
# --- Stage 2: Dell EMC racadm build ---
FROM nicat23/racadm:latest AS emc
# --- Final Stage ---
FROM alpine:3.23

RUN addgroup -g 1000 -S appgroup && \
    adduser -u 1000 -S appuser -G appgroup -s /bin/sh && \
    apk update --no-cache && apk upgrade --no-cache && \
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
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/* && \
    apk del --purge \
        $(apk info --installed | grep -E '^(pkgconf|build-base|gcc|musl-dev)' \
        | cut -d' ' -f1) 2>/dev/null || true && \
    # Create logrotate config for acme.sh
    printf "%b" "/config/acme.sh.log {\n\
    daily\n\
    rotate 7\n\
    missingok\n\
    notifempty\n\
    compress\n\
    delaycompress\n\
    copytruncate\n\
    }\n" > /etc/logrotate.d/acme.sh && \
    printf "%b" "#!/bin/sh\n/usr/sbin/logrotate /etc/logrotate.conf\n" \
    > /etc/periodic/daily/logrotate &&\
    chmod a+x /etc/periodic/daily/logrotate && \
    [ ! -e /usr/lib/libssl.so ] && { \
    if [ -e /usr/lib/libssl.so.3 ]; then \
    ln -s /usr/lib/libssl.so.3 /usr/lib/libssl.so; \
    elif [ -e /usr/lib64/libssl.so.3 ]; then \
    ln -s /usr/lib64/libssl.so.3 /usr/lib/libssl.so; \
    fi; \
    }
COPY --chown=appuser:appgroup ./init /init
# Copy acme.sh environment
COPY --from=acme --chown=appuser:appgroup /acme.sh /acme.sh
COPY --from=acme --chown=appuser:appgroup /acmebin /acmebin
COPY --from=acme --chown=appuser:appgroup /usr/local/bin/acme.sh /usr/local/bin/acme.sh
COPY --from=acme --chown=appuser:appgroup /usr/local/bin/--* /usr/local/bin/
#COPY --from=acme --chown=root:root /entry.sh /entry.sh

# Copy racadm and dependencies
COPY --from=emc  /opt/dell /opt/dell
COPY --from=emc  /usr/bin/racadm /usr/bin/racadm
# Install all required packages with latest versions and security updates
COPY --chown=root:root ./entry.sh /entry.sh
ARG AUTO_UPGRADE=1 \
    LE_WORKING_DIR=/acmebin \
    LE_CONFIG_HOME=/acme.sh \
    LE_CERT_HOME=/certs

ENV LE_WORKING_DIR=$LE_WORKING_DIR \
    LE_CONFIG_HOME=$LE_CONFIG_HOME \
    LE_CERT_HOME=$LE_CERT_HOME \
    AUTO_UPGRADE=$AUTO_UPGRADE \
    # Security environment variables
    PAGER=cat \
    SHELL=/bin/sh

# Create/Change ownership
RUN mkdir -p ${LE_CERT_HOME} ${LE_CONFIG_HOME} /hooks && \
    chown appuser:appgroup ${LE_CERT_HOME} ${LE_CONFIG_HOME} /hooks && \
    chmod 750 ${LE_CERT_HOME} ${LE_CONFIG_HOME} /hooks && \
    printf "%b" "\
    Defaults env_reset\n\
    Defaults secure_path=\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\"\n\
    Defaults passwd_timeout=0\n\
    Defaults !requiretty\n\
    %appgroup ALL=(root) NOPASSWD: /usr/bin/racadm, /opt/dell/srvadmin/bin/idracadm7, /usr/sbin/crond, /bin/chmod\n" \
    > /etc/sudoers.d/app && \
    chmod 0440 /etc/sudoers.d/app && \
    # Test sudo configuration
    visudo -c && \
    # Make entry script executable and owned by root for security
    chown root:root /entry.sh && \
    chmod 755 /entry.sh && \
    chmod 755 /init/overlay.sh && \
    # Create a test to ensure racadm works
    # Test that sudo is configured correctly (without actually running racadm)
    sudo -u appuser sudo -l | grep -q racadm && echo "Sudo configuration verified" || echo "Sudo configuration failed"
# Use non-root user
USER appuser

VOLUME ["/certs", "${LE_CONFIG_HOME}", "/hooks"]
WORKDIR ${LE_WORKING_DIR}
#SHELL ["/bin/sh", "-c"]
ENTRYPOINT ["/entry.sh"]
CMD ["--help"]
