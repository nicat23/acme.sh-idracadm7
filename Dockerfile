FROM alpine:3.22

ARG AUTO_UPGRADE=1 \
	LE_WORKING_DIR=/acme.sh \
    LE_CONFIG_HOME=$LE_WORKING_DIR/config \
    LE_CERT_HOME=/certs

ENV LE_WORKING_DIR=$LE_WORKING_DIR \
	LE_CONFIG_HOME=$LE_CONFIG_HOME \
    LE_CERT_HOME=$LE_CERT_HOME \
	AUTO_UPGRADE=$AUTO_UPGRADE

#Copy acme.sh
COPY ./acme.sh /install_acme.sh/acme.sh
COPY ./deploy /install_acme.sh/deploy
COPY ./dnsapi /install_acme.sh/dnsapi
COPY ./notify /install_acme.sh/notify
COPY ./init/ /init/
COPY ./entry.sh /entry.sh

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
	; done

VOLUME ["/certs", "${LE_WORKING_DIR}/config", "/hooks"]

ENTRYPOINT ["/entry.sh"]
CMD ["--help"]
