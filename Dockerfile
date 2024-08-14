FROM alpine:${ALPINE_VERSION:-3.20}

RUN apk add --update --no-cache net-snmp net-snmp-tools envsubst

COPY entrypoint.sh /usr/local/bin/

COPY etc/snmp/ /etc/snmp/

EXPOSE 161/udp

ENTRYPOINT ["entrypoint.sh"]
