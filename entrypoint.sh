#!/usr/bin/env bash

sh -c 'nginx &'

sum=$(tar -cf - /etc/nginx/sites-enabled | md5sum | cut -d' ' -f 1)

echo $sum
while true; do
	n_sum=$(tar -cf - . | md5sum | cut -d' ' -f 1)
    if [ "$sum" = "$n_sum" ]; then
	    sleep 1
	    continue
    fi
    sum=$n_sum
    nginx -s reload
done
