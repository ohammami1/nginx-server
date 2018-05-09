#
# Nginx Dockerfile
#
# https://github.com/dockerfile/nginx
#
# Pull base image.
FROM nginx:1.12

ADD nginx.conf /etc/nginx/
ADD /entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh
RUN usermod -u 1000 www-data

CMD ["nginx"]

ENTRYPOINT ["/entrypoint.sh"]
WORKDIR "/etc/nginx"
