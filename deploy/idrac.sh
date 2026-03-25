#!/usr/bin/env sh
# Usage:

## put this script in the deploy/ directory in the acme.sh USER

#export DEPLOY_IDRAC_HOST="HOST"
#export DEPLOY_IDRAC_PASS="PASSWORD"
#export DEPLOY_IDRAC_USER="USER"

## Issue the cert, I use CF
# acme.sh --issue --dns dns_cf -d "HOST" -k 2048
# acme.sh --deploy -d "HOST"  --deploy-hook idrac

idrac_deploy() {
	_cdomain="$1"
	_ckey="$2"
	_ccert="$3"
	_cca="$4"
	_cfullchain="$5"

	_debug _cdomain "$_cdomain"
	_debug _ckey "$_ckey"
	_debug _ccert "$_ccert"
	_debug _cca "$_cca"
	_debug _cfullchain "$_cfullchain"

	_getdeployconf Le_Deploy_idrac_user
	_getdeployconf Le_Deploy_idrac_pass
	_getdeployconf Le_Deploy_idrac_host

	if [ -z "$Le_Deploy_idrac_user" ] || [ -z "$Le_Deploy_idrac_pass" ] || [ -z "$Le_Deploy_idrac_host" ]; then
		if [ -z "$DEPLOY_IDRAC_USER" ] || [ -z "$DEPLOY_IDRAC_PASS" ] || [ -z "$DEPLOY_IDRAC_HOST" ]; then
				_err "Both deployment configuration and environment variables are missing. Please set them."
				_err "Usage examples:"
				_err "export DEPLOY_IDRAC_HOST=\"HOST\""
				_err "export DEPLOY_IDRAC_PASS=\"PASSWORD\""
				_err "export DEPLOY_IDRAC_USER=\"USER\""
				_err "acme.sh --issue --dns dns_cf -d \"HOST\" -k 2048"
				_err "acme.sh --deploy -d \"HOST\"  --deploy-hook idrac"
				return 1
		else
			Le_Deploy_idrac_user="$DEPLOY_IDRAC_USER"
			Le_Deploy_idrac_pass="$DEPLOY_IDRAC_PASS"
			Le_Deploy_idrac_host="$DEPLOY_IDRAC_HOST"
			_savedeployconf Le_Deploy_idrac_user "$Le_Deploy_idrac_user"
			_savedeployconf Le_Deploy_idrac_pass "$Le_Deploy_idrac_pass"
			_savedeployconf Le_Deploy_idrac_host "$Le_Deploy_idrac_host"
		fi
	fi

	_info "Starting iDRAC deployment"
	_debug2 Le_Deploy_idrac_user "$Le_Deploy_idrac_user"
	_debug2 Le_Deploy_idrac_pass "$Le_Deploy_idrac_pass"
	_debug2 Le_Deploy_idrac_host "$Le_Deploy_idrac_host"

	_info "Uploading SSL key to $Le_Deploy_idrac_host"
	if [ ! "$(racadm -r "$Le_Deploy_idrac_host" -u "$Le_Deploy_idrac_user" -p "$Le_Deploy_idrac_pass" sslkeyupload -t 1 -f "$_ckey")" ]; then
		_err "Failed to upload SSL key."
		return 1
	fi

	_info "Uploading SSL certificate to $Le_Deploy_idrac_host"
	if [ ! "$(racadm -r "$Le_Deploy_idrac_host" -u "$Le_Deploy_idrac_user" -p "$Le_Deploy_idrac_pass" sslcertupload -t 1 -f "$_cfullchain")" ]; then
		_err "Failed to upload SSL certificate."
		return 1
	fi

	_info "Resetting iDRAC on $Le_Deploy_idrac_host"
	if [ ! "$(racadm -r "$Le_Deploy_idrac_host" -u "$Le_Deploy_idrac_user" -p "$Le_Deploy_idrac_pass" racreset)" ]; then
		_err "Failed to reset iDRAC."
		return 1
	fi

	_info "iDRAC deployment finished successfully"
	return 0

}
