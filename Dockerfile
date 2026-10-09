# --- Stage 1: acme.sh ---
FROM neilpang/acme.sh:latest AS acme

# --- Stage 2: Dell EMC racadm build ---
FROM nicat23/racadm:latest AS emc

# --- Final Stage (glibc, deterministic) ---
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Create app user/group
RUN groupadd -g 1000 appgroup && \
    useradd -u 1000 -g appgroup -s /bin/sh -M appuser

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openssl \
        openssh-client \
        coreutils \
        dnsutils \
        curl \
        sed \
        socat \
        tzdata \
        oathtool \
        tar \
        jq \
        cron \
        logrotate \
        sudo \
        dmidecode \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Copy init scripts
COPY --chown=appuser:appgroup ./init /init

# Copy acme.sh environment
COPY --from=acme --chown=appuser:appgroup /acme.sh /acme.sh
COPY --from=acme --chown=appuser:appgroup /acmebin /acmebin
COPY --from=acme --chown=appuser:appgroup /usr/local/bin/acme.sh /usr/local/bin/acme.sh
COPY --from=acme --chown=appuser:appgroup /usr/local/bin/--* /usr/local/bin/

# Copy racadm + Dell stack
COPY --from=emc /opt/dell /opt/dell
COPY --from=emc /usr/bin/racadm /usr/bin/racadm

# Entry script
COPY --chown=root:root ./entry.sh /entry.sh

# Environment
ARG AUTO_UPGRADE=1 \
    LE_WORKING_DIR=/acmebin \
    LE_CONFIG_HOME=/acme.sh \
    LE_CERT_HOME=/certs

ENV LE_WORKING_DIR=$LE_WORKING_DIR \
    LE_CONFIG_HOME=$LE_CONFIG_HOME \
    LE_CERT_HOME=$LE_CERT_HOME \
    AUTO_UPGRADE=$AUTO_UPGRADE \
    PAGER=cat \
    SHELL=/bin/sh

# Permissions, sudoers, logrotate
RUN mkdir -p ${LE_CERT_HOME} ${LE_CONFIG_HOME} /hooks && \
    chown appuser:appgroup ${LE_CERT_HOME} ${LE_CONFIG_HOME} /hooks && \
    chmod 750 ${LE_CERT_HOME} ${LE_CONFIG_HOME} /hooks && \
    printf "%b" "\
Defaults env_reset\n\
Defaults secure_path=\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\"\n\
Defaults passwd_timeout=0\n\
Defaults !requiretty\n\
%appgroup ALL=(root) NOPASSWD: /usr/bin/racadm, /opt/dell/srvadmin/bin/idracadm7, /usr/sbin/cron, /bin/chmod\n" \
    > /etc/sudoers.d/app && \
    chmod 0440 /etc/sudoers.d/app && \
    visudo -c && \
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
    > /etc/cron.daily/logrotate && \
    chmod 755 /etc/cron.daily/logrotate && \
    chmod 755 /entry.sh && \
    chmod 755 /init/overlay.sh && \
    sudo -u appuser sudo -l | grep -q racadm && echo "Sudo configuration verified"

USER appuser

VOLUME ["/certs", "${LE_CONFIG_HOME}", "/hooks"]

WORKDIR ${LE_WORKING_DIR}

ENTRYPOINT ["/entry.sh"]
CMD ["--help"]
