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

    Le_Deploy_idrac_user="$DEPLOY_IDRAC_USER"
    _savedomainconf Le_Deploy_idrac_user "$Le_Deploy_idrac_user"
    Le_Deploy_idrac_pass="$DEPLOY_IDRAC_PASS"
    _savedomainconf Le_Deploy_idrac_pass "$Le_Deploy_idrac_pass"
    Le_Deploy_idrac_host="$DEPLOY_IDRAC_HOST"
    _savedomainconf Le_Deploy_idrac_host "$Le_Deploy_idrac_host"

    #/opt/dell/srvadmin/bin/idracadm7 -r "$Le_Deploy_idrac_host" -u "$Le_Deploy_idrac_user" -p "$Le_Deploy_idrac_pass" sslkeyupload -t 1 -f $_ckey
    #/opt/dell/srvadmin/bin/idracadm7 -r "$Le_Deploy_idrac_host" -u "$Le_Deploy_idrac_user" -p "$Le_Deploy_idrac_pass" sslcertupload -t 1 -f $_cfullchain
    #/opt/dell/srvadmin/bin/idracadm7 -r "$Le_Deploy_idrac_host" -u "$Le_Deploy_idrac_user" -p "$Le_Deploy_idrac_pass" racreset

    racadm -r "$Le_Deploy_idrac_host" -u "$Le_Deploy_idrac_user" -p "$Le_Deploy_idrac_pass" sslkeyupload -t 1 -f $_ckey
    racadm -r "$Le_Deploy_idrac_host" -u "$Le_Deploy_idrac_user" -p "$Le_Deploy_idrac_pass" sslcertupload -t 1 -f $_cfullchain
    racadm -r "$Le_Deploy_idrac_host" -u "$Le_Deploy_idrac_user" -p "$Le_Deploy_idrac_pass" racreset

}