#! /bin/bash

# set -e
# set -x

code=0

docker build . --no-cache -t snmpd-container-test

SNMP_V3_USER="testainers"
SNMP_V3_AUTH_PROTOCOL="SHA"
SNMP_V3_AUTH_PWD="auth999pass"

docker run --rm --name snmpd -p 5161:161/udp -d \
  -e SNMP_V3_USER=$SNMP_V3_USER \
  -e SNMP_V3_AUTH_PROTOCOL=$SNMP_V3_AUTH_PROTOCOL \
  -e SNMP_V3_AUTH_PWD=$SNMP_V3_AUTH_PWD \
  snmpd-container-test

sleep 2

# TODO: Check the result.
# snmpwalk -v 2c -c public localhost:5161 .1.3.6.1.2.1.1

result=$(snmpget -v2c -c public -Ovq localhost:5161 .1.3.6.1.2.1.1.6.0)

if [ "$result" != "At flying circus" ]; then
  code=10
fi

result=$(snmpgetnext -v2c -c public -Ovq localhost:5161 .1.3.6.1.2.1.1.6.0)

if [ "$result" != "72" ]; then
  code=11
fi

# TODO: Check the result.
# snmpwalk -v3 -On -u "$SNMP_V3_USER" \
#   -l authNoPriv \
#   -a "$SNMP_V3_AUTH_PROTOCOL" \
#   -A "$SNMP_V3_AUTH_PWD" \
#   localhost:5161 \
#   .1.3.6.1.2.1.1

result=$(snmpget -v3 -Ovq -u "$SNMP_V3_USER" \
  -l authNoPriv \
  -a "$SNMP_V3_AUTH_PROTOCOL" \
  -A "$SNMP_V3_AUTH_PWD" \
  localhost:5161 \
  .1.3.6.1.2.1.1.6.0)

if [ "$result" != "At flying circus" ]; then
  code=20
fi

result=$(snmpgetnext -v3 -Ovq -u "$SNMP_V3_USER" \
  -l authNoPriv \
  -a "$SNMP_V3_AUTH_PROTOCOL" \
  -A "$SNMP_V3_AUTH_PWD" \
  localhost:5161 \
  .1.3.6.1.2.1.1.6.0)

if [ "$result" != "72" ]; then
  code=21
fi

#echo "====================================="
#docker logs snmpd
#echo "====================================="

docker stop -t 1 snmpd

sleep 2

SNMP_V3_PRIV_PROTOCOL="AES"
SNMP_V3_PRIV_PWD="priv999pass"

docker run --rm --name snmpd -p 5161:161/udp -d \
  -e SNMP_V3_USER=$SNMP_V3_USER \
  -e SNMP_V3_AUTH_PROTOCOL=$SNMP_V3_AUTH_PROTOCOL \
  -e SNMP_V3_AUTH_PWD=$SNMP_V3_AUTH_PWD \
  -e SNMP_V3_PRIV_PROTOCOL=$SNMP_V3_PRIV_PROTOCOL \
  -e SNMP_V3_PRIV_PWD=$SNMP_V3_PRIV_PWD \
  snmpd-container-test

sleep 2

result=$(snmpget -v3 -Ovq -u "$SNMP_V3_USER" \
  -l authPriv \
  -a "$SNMP_V3_AUTH_PROTOCOL" \
  -A "$SNMP_V3_AUTH_PWD" \
  -x "$SNMP_V3_PRIV_PROTOCOL" \
  -X "$SNMP_V3_PRIV_PWD" \
  localhost:5161 \
  .1.3.6.1.2.1.1.6.0)

if [ "$result" != "At flying circus" ]; then
  code=30
fi

result=$(snmpgetnext -v3 -Ovq -u "$SNMP_V3_USER" \
  -l authPriv \
  -a "$SNMP_V3_AUTH_PROTOCOL" \
  -A "$SNMP_V3_AUTH_PWD" \
  -x "$SNMP_V3_PRIV_PROTOCOL" \
  -X "$SNMP_V3_PRIV_PWD" \
  localhost:5161 \
  .1.3.6.1.2.1.1.6.0)

if [ "$result" != "72" ]; then
  code=31
fi

#echo "====================================="
#docker logs snmpd
#echo "====================================="

docker stop -t 1 snmpd

sleep 2

docker image rm snmpd-container-test

exit $code
