FROM alpine:3
MAINTAINER d@d.ru
MAINTAINER daniel.sanchez@aranova.es

RUN apk add --no-cache dcron curl ca-certificates mysql-client py-pip && pip install s3cmd
RUN mkdir -p /var/log/cron && mkdir -m 0644 -p /var/spool/cron/crontabs && touch /var/log/cron/cron.log && mkdir -m 0644 -p /etc/cron.d
RUN apk add --no-cache tzdata && cp /usr/share/zoneinfo/Europe/Madrid /etc/localtime && apk del tzdata

COPY /scripts/* /

ENTRYPOINT ["/docker-entry.sh"]
CMD ["/docker-cmd.sh"]
