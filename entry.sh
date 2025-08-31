#!/usr/bin/env sh
if [ -d "$LE_CONFIG_HOME" ] && { [ ! -f "$LE_CONFIG_HOME/account.conf" ] || [ \
	! -f "$LE_CONFIG_HOME/http.header" ]; }; then
    #files are missing, run --upgarde to generate them
	echo "🆕 account.conf or http.header missing in $LE_CONFIG_HOME. Running acme.sh \
		--upgrade to initialize..."
    /acme.sh/acme.sh --upgrade --cert-home $LE_CERT_HOME --config-home $LE_CONFIG_HOME \
		 --home $LE_WORKING_DIR --debug 
else
    echo "✅ Both account.conf and http.header detected in $LE_CONFIG_HOME"
fi

if [ -f /init/overlay.sh ]; then
	echo '🚀 Running container initialization...'
	/init/overlay.sh
fi

if [ "$1" = "daemon" ]; then
	exec crond -n -s -m off
else
	exec -- "$@"
fi
