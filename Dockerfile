FROM alpine:3
MAINTAINER d@d.ru
MAINTAINER daniel.sanchez@aranova.es			   

LABEL org.opencontainers.image.source https://github.com/ARANOVA/docker-alpine-cron

RUN apk add --no-cache dcron curl ca-certificates mysql-client mariadb-connector-c mongodb-tools bash py-pip dos2unix && pip install awscli

RUN mkdir -p /var/log/cron && mkdir -m 0644 -p /var/spool/cron/crontabs && touch /var/log/cron/cron.log && mkdir -m 0644 -p /etc/cron.d
RUN apk add --no-cache tzdata && cp /usr/share/zoneinfo/Europe/Madrid /etc/localtime && apk del tzdata

COPY /scripts/ /
RUN dos2unix /mysql/* && dos2unix /mongo/* && dos2unix /*.sh && chmod a+x /*.sh && chmod a+x /mysql/*.sh && chmod a+x /mongo/*.sh

ENTRYPOINT ["/docker-entry.sh"]
CMD ["/docker-cmd.sh"]
