FROM alpine:3.14
MAINTAINER d@d.ru

RUN apk add --no-cache dcron curl ca-certificates
RUN mkdir -p /var/log/cron && mkdir -m 0644 -p /var/spool/cron/crontabs && touch /var/log/cron/cron.log && mkdir -m 0644 -p /etc/cron.d
RUN apk add --no-cache tzdata && cp /usr/share/zoneinfo/Europe/Madrid /etc/localtime && apk del tzdata

COPY /scripts/* /

ENTRYPOINT ["/docker-entry.sh"]
CMD ["/docker-cmd.sh"]
