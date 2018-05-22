#!/usr/bin/env bash

pid=$$
nginx >/proc/$pid/fd/1 &

cd /etc/nginx/sites-enabled
sum=$(tar -cf - . | md5sum | cut -d' ' -f 1)

while true; do
    n_sum=$(tar -cf - . | md5sum | cut -d' ' -f 1)
    if [ "$sum" = "$n_sum" ]; then
	    sleep 1
	    continue
    fi
    sum=$n_sum
    if pgrep nginx >/dev/null 2>&1; then 
    	nginx -s reload
    else
	nginx &
    fi
done
