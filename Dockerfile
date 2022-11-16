FROM alpine:3.16.2

LABEL org.opencontainers.image.authors="inadsan@gmail.com"
LABEL org.opencontainers.image.source https://github.com/inadsan/docker-alpine-cron

RUN apk add --no-cache dcron curl ca-certificates mysql-client mariadb-connector-c bash dos2unix coreutils tar py-pip && pip install s3cmd

RUN mkdir -p /var/log/cron && mkdir -m 0644 -p /var/spool/cron/crontabs && touch /var/log/cron/cron.log && mkdir -m 0644 -p /etc/cron.d
RUN apk add --no-cache tzdata && cp /usr/share/zoneinfo/Europe/Madrid /etc/localtime && apk del tzdata

COPY /scripts/ /
RUN dos2unix /base/* && dos2unix /folder/* && dos2unix /mysql/* && dos2unix /portainer/* && dos2unix /*.sh && chmod a+x /*.sh && chmod a+x /mysql/*.sh && chmod a+x /folder/*.sh && chmod a+x /portainer/*.sh

ENTRYPOINT ["/docker-entry.sh"]
CMD ["/docker-cmd.sh"]
