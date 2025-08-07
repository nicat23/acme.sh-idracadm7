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
  libstdc++


ENV LE_CONFIG_HOME=/config
#Install directory for the original files
ENV LE_WORKING_DIR=/defaults 
ENV LE_CERT_HOME=/certs
ENV LE_BASE=/acme
ARG AUTO_UPGRADE=1

ENV AUTO_UPGRADE=$AUTO_UPGRADE
#RUN mkdir /certs /config /acme.sh
# Install Dell iDRAC software using rpm
RUN rpm -ivh --nodeps --force \
  https://linux.dell.com/repo/hardware/DSU_24.11.11/os_dependent/RHEL9_64/srvadmin/srvadmin-argtable2-11.0.0.0-5268.el9.x86_64.rpm \
  https://linux.dell.com/repo/hardware/DSU_24.11.11/os_dependent/RHEL9_64/srvadmin/srvadmin-hapi-11.0.0.0-5268.el9.x86_64.rpm \
  https://linux.dell.com/repo/hardware/DSU_24.11.11/os_dependent/RHEL9_64/srvadmin/srvadmin-idracadm7-11.0.0.0-5268.el9.x86_64.rpm 
RUN [ ! -e /usr/lib/libssl.so ] && { [ -e /usr/lib/libssl.so.3 ] && ln -s /usr/lib/libssl.so.3 /usr/lib/libssl.so || \ 
  { [ -e /usr/lib64/libssl.so.3 ] && ln -s /usr/lib64/libssl.so.3 /usr/lib/libssl.so; }; }
RUN ln -s /opt/dell/srvadmin/bin/idracadm7 /usr/bin/racadm

#Install acme.sh
COPY ./acme.sh /install_acme.sh/acme.sh
COPY ./deploy /install_acme.sh/deploy
COPY ./dnsapi /install_acme.sh/dnsapi
COPY ./notify /install_acme.sh/notify
RUN cd /install_acme.sh && ([ -f /install_acme.sh/acme.sh ] && /install_acme.sh/acme.sh --install --home ${LE_WORKING_DIR} \
  --config-home ${LE_CONFIG_HOME} --cert-home ${LE_CERT_HOME} || curl https://get.acme.sh | sh --home ${LE_WORKING_DIR} --config-home ${LE_CONFIG_HOME} \
  --cert-home ${LE_CERT_HOME}) && rm -rf /install_acme.sh/


RUN ln -s ${LE_WORKING_DIR}/acme.sh /usr/local/bin/acme.sh && crontab -l | grep acme.sh | \
  sed 's#> /dev/null#> /proc/1/fd/1 2>/proc/1/fd/2#' | crontab - && chmod +x /usr/local/bin/acme.sh && \
  apk del jq 

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
    printf -- "%b" "#!/usr/bin/env sh\n${LE_WORKING_DIR}/acme.sh --${verb} \
      --config-home ${LE_CONFIG_HOME}  \"\$@\"" >/usr/local/bin/--${verb} \
      && chmod +x /usr/local/bin/--${verb} \
  ; done

RUN printf "%b" '#!'"/usr/bin/env sh\n \
if [ \"\$1\" = \"daemon\" ];  then \n \
  exec crond -n -s -m off 2>&1 \n \
else \n \
  exec -- \"\$@\"\n 2>&1 \n \
fi\n" >/entry.sh && chmod +x /entry.sh

ENTRYPOINT ["/entry.sh"]
VOLUME [ "/certs" ]
CMD ["--help"]