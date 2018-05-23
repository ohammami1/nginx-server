#!/usr/bin/env bash

CONF_PATH=/etc/nginx/sites-enabled
ARCHIVE_PATH=/etc/nginx/.sites/
mkdir -p ${ARCHIVE_PATH} || true

pid=$$
nginx -T >/proc/$pid/fd/1 &
sum=$(tar -cf - . | md5sum | cut -d' ' -f 1)
cd $CONF_PATH
cp $CONF_PATH/* $ARCHIVE_PATH/

while true; do
	for cfile in $(ls ${CONF_PATH}/); do
		rhost=$(cat ${CONF_PATH}/$cfile | grep 'server ' \
					| tr -d '#' | tr -d '{' | tr '\t' ' ' | tr -s ' ' \
					| cut -d' ' -f 3 | cut -d':' -f 1 | tr -d ';' \
					| sed '/^\s*$/d')
		if ! [ "$rhost" ]; then
			continue;
		fi

		if ! ping -c1 -W1 $rhost > /dev/null 2>&1; then
			sed -i -e 's/##autocomment## //g' $cfile
			sed -i -e 's/^/##autocomment## /g' $cfile
		else
			commented=true
			for line in $(cat $cfile | tr '\t' ' ' | tr ' ' ':'); do
				if echo $line | grep -v '##autocomment##' >/dev/null 2>&1; then
					commented=false
					break;
				fi
			done

			if $commented; then
				sed -i -e 's/##autocomment## //g' $cfile
			fi
		fi
	done

	if [ "$(ls $ARCHIVE_PATH)" != "$(ls $CONF_PATH)" ]; then
		echo "Config Files Changed"
		echo "Archives: $(ls $ARCHIVE_PATH)"
		echo "CONFS: $(ls $CONF_PATH)"
		echo "Reloading Server.."
		rm -rf ${ARCHIVE_PATH}/*
		cp ${CONF_PATH}/* ${ARCHIVE_PATH}
		if pgrep nginx >/dev/null 2>&1; then
    			nginx -s reload
    		else
			nginx &
		fi
		continue
	fi

	for cfile in $(ls ${CONF_PATH}/); do
		if [ "$(cat ${CONF_PATH}/${cfile})" != "$(cat ${ARCHIVE_PATH}/${cfile})" ]; then
			echo "One file changed: $cfile"
			echo "Reloading Server.."
			rm -rf ${ARCHIVE_PATH}/*
			cp ${CONF_PATH}/* ${ARCHIVE_PATH}
			if pgrep nginx >/dev/null 2>&1; then
    				nginx -s reload
   	 		else
				nginx &
			fi
			continue
		fi
	done
	sleep 5
done
