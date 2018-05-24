#!/usr/bin/env bash

CONF_PATH=/etc/nginx/sites-enabled
ARCHIVE_PATH=/etc/nginx/.sites
mkdir ${ARCHIVE_PATH}

pid=$$
sum=$(tar -cf - . | md5sum | cut -d' ' -f 1)
cd $CONF_PATH
cp $CONF_PATH/* $ARCHIVE_PATH/
#mv $CONF_PATH/* $ARCHIVE_PATH/ || true

nginx -T >/proc/$pid/fd/1 2>&1 
nginx >/proc/$pid/fd/1 2>&1 &
#sleep 2
#cp $ARCHIVE_PATH/* $CONF_PATH/
#pkill nginx || true && nginx -T > /proc/$pid/fd/1 2>&1 &

while true; do
	for cfile in $(ls ${CONF_PATH}/); do
		rhostport=$(cat ${CONF_PATH}/$cfile | grep 'server ' \
					| tr -d '#' | tr -d '{' | tr '\t' ' ' | tr -s ' ' \
					| cut -d' ' -f 3 | tr -d ';' \
					| sed '/^\s*$/d')
		rhost=$(echo $rhostport | cut -d':' -f 1)
		rport=$(echo $rhostport | cut -d':' -f 2)

		if ! [ "$rhost" ]; then
			continue;
		fi

		if ! ping -c1 -W1 $rhost > /dev/null 2>&1 \
			|| [ "$rport" ] && ! nc -z $rhost $rport >/dev/null 2>&1; then
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

	if ! pgrep nginx >/dev/null 2>&1; then
		nginx -T > /proc/$pid/fd/1 2>&1 
		nginx &
	fi

	if [ "$(ls $ARCHIVE_PATH)" != "$(ls $CONF_PATH)" ]; then
		echo "Config Files Changed"
		echo "Archives: $(ls $ARCHIVE_PATH)"
		echo "CONFS: $(ls $CONF_PATH)"
		echo "Reloading Server.."
		rm -rf ${ARCHIVE_PATH}/*
		cp ${CONF_PATH}/* ${ARCHIVE_PATH}
		
		nginx -T > /proc/$pid/fd/1 2>&1 
		nginx -s reload
		continue
	fi


	for cfile in $(ls ${CONF_PATH}/); do
		if [ "$(cat ${CONF_PATH}/${cfile})" != "$(cat ${ARCHIVE_PATH}/${cfile})" ]; then
			echo "One file changed: $cfile"
			echo "Reloading Server.."
			rm -rf ${ARCHIVE_PATH}/*
			cp ${CONF_PATH}/* ${ARCHIVE_PATH}
#			if pgrep nginx >/dev/null 2>&1; then
#				nginx -s reload >/proc/$pid/fd/1 &
#   	 		else
#				nginx > /proc/$pid/fd/1 &
#			fi

		       	nginx -T > /proc/$pid/fd/1 2>&1 
			nginx -s reload
			continue
		fi
	done
	sleep 5
done
