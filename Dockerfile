#start with a small base
FROM alpine:3.22

RUN apk --no-cache add -f \
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
  rpm \
  gcompat \
  libc6-compat \
  libstdc++ \
  su-exec

# Create default user with UID/GID 1000
RUN addgroup -g 1000 apps && \
    adduser -D -u 1000 -G apps apps

# User configuration
ENV PUID=1000
ENV PGID=1000
ENV USERNAME=apps

# ACME.sh configuration
ENV LE_CONFIG_HOME=/acme.sh

ARG AUTO_UPGRADE=1
ENV AUTO_UPGRADE=$AUTO_UPGRADE

# Install Dell iDRAC software using rpm
RUN rpm -ivh --nodeps --force \
  https://linux.dell.com/repo/hardware/DSU_24.11.11/os_dependent/RHEL9_64/srvadmin/srvadmin-argtable2-11.0.0.0-5268.el9.x86_64.rpm \
  https://linux.dell.com/repo/hardware/DSU_24.11.11/os_dependent/RHEL9_64/srvadmin/srvadmin-hapi-11.0.0.0-5268.el9.x86_64.rpm \
  https://linux.dell.com/repo/hardware/DSU_24.11.11/os_dependent/RHEL9_64/srvadmin/srvadmin-idracadm7-11.0.0.0-5268.el9.x86_64.rpm 

#Check for /usr/libssl.so - if not found check for alternatives and symlink
RUN [ ! -e /usr/lib/libssl.so ] && { [ -e /usr/lib/libssl.so.3 ] && ln -s /usr/lib/libssl.so.3 /usr/lib/libssl.so || \ 
  { [ -e /usr/lib64/libssl.so.3 ] && ln -s /usr/lib64/libssl.so.3 /usr/lib/libssl.so; }; }

#ln -s /usr/lib/libssl.so.3 /usr/lib/libssl.so || ln -s /usr/lib64/libssl.so.3 /usr/lib/libssl.so
RUN ln -s /opt/dell/srvadmin/bin/idracadm7 /usr/bin/racadm

#Install
COPY ./acme.sh /install_acme.sh/acme.sh
RUN cd /install_acme.sh && ([ -f /install_acme.sh/acme.sh ] && /install_acme.sh/acme.sh --install || \
  curl https://get.acme.sh | sh) && rm -rf /install_acme.sh/

# Copy custom scripts into image to install path
COPY ./deploy /root/.acme.sh/deploy
COPY ./dnsapi /root/.acme.sh/dnsapi
COPY ./notify /root/.acme.sh/notify

RUN ln -s /root/.acme.sh/acme.sh /usr/local/bin/acme.sh && crontab -l | grep acme.sh | \
  sed 's#> /dev/null#> /proc/1/fd/1 2>/proc/1/fd/2#' | crontab -

RUN for verb in help \
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
    printf -- "%b" "#!/usr/bin/env sh\n/root/.acme.sh/acme.sh --${verb} --config-home /acme.sh \"\$@\"" \
      >/usr/local/bin/--${verb} && chmod +x /usr/local/bin/--${verb} \
  ; done

RUN printf "%b" '#!'"/usr/bin/env sh\n \
# Set defaults\n \
PUID=\${PUID:-1000}\n \
PGID=\${PGID:-1000}\n \
USERNAME=\${USERNAME:-apps}\n \
\n \
# Handle user ID changes\n \
if [ \"\$PUID\" != \"0\" ] && [ \"\$PGID\" != \"0\" ]; then\n \
    echo \"Setting user ID to \$PUID and group ID to \$PGID (username: \$USERNAME)\"\n \
    \n \
    # Get current user/group info\n \
    CURRENT_USER=\$(getent passwd \"\$PUID\" | cut -d: -f1)\n \
    CURRENT_GROUP=\$(getent group \"\$PGID\" | cut -d: -f1)\n \
    \n \
    # Create group if it doesn't exist or modify existing\n \
    if [ -z \"\$CURRENT_GROUP\" ]; then\n \
        addgroup -g \"\$PGID\" \"\$USERNAME\"\n \
        GROUP_NAME=\"\$USERNAME\"\n \
    else\n \
        GROUP_NAME=\"\$CURRENT_GROUP\"\n \
    fi\n \
    \n \
    # Create or modify user\n \
    if [ -z \"\$CURRENT_USER\" ]; then\n \
        adduser -D -u \"\$PUID\" -G \"\$GROUP_NAME\" \"\$USERNAME\"\n \
        USER_NAME=\"\$USERNAME\"\n \
    else\n \
        USER_NAME=\"\$CURRENT_USER\"\n \
    fi\n \
    \n \
    # Ensure acme.sh directories exist and set ownership\n \
    mkdir -p /acme.sh\n \
    chown -R \"\$PUID:\$PGID\" /acme.sh /root/.acme.sh\n \
    \n \
    # Execute as the specified user\n \
    if [ \"\$1\" = \"daemon\" ]; then\n \
        exec su-exec \"\$PUID:\$PGID\" crond -n -s -m off\n \
    elif [ \"\$1\" = \"racadm\" ]; then\n \
        shift\n \
        exec su-exec \"\$PUID:\$PGID\" racadm \"\$@\"\n \
    else\n \
        exec su-exec \"\$PUID:\$PGID\" \"\$@\"\n \
    fi\n \
else\n \
    # Run as root when PUID/PGID is 0\n \
    if [ \"\$1\" = \"daemon\" ]; then\n \
        exec crond -n -s -m off\n \
    elif [ \"\$1\" = \"racadm\" ]; then\n \
        shift\n \
        exec racadm \"\$@\"\n \
    else\n \
        exec -- \"\$@\"\n \
    fi\n \
fi\n" >/entry.sh && chmod +x /entry.sh

VOLUME /acme.sh

ENTRYPOINT ["/entry.sh"]
CMD ["--help"]