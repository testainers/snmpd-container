#! /bin/bash

# set -e
# set -x

CODE=0

# Name of the image
IMAGE_NAME="snmpd-container-test"

# Name of the container
CONTAINER_NAME="snmpd"

# Host bind address
HOST="localhost"

# Host bind port
PORT=5161

# OID for snmpwalk
WALK=".1.3.6.1.2.1.1"

# OID for snmpget and snmpgetnext
GET=".1.3.6.1.2.1.1.6.0"

###############
# Build Image #
###############

docker build . --no-cache -t "$IMAGE_NAME"

SNMP_V3_USER="testainers"

###########
# SNMPv2c #
###########

docker run --rm --name "$CONTAINER_NAME" -p "$PORT:161/udp" -d "$IMAGE_NAME"

sleep 2

# SNMPv2c - Walk
snmpwalk -v 2c -c public "$HOST:$PORT" "$WALK" >/dev/null 2>&1

if [ $? -ne 0 ]; then
  CODE=10
fi

# SNMPv2c - Get
RESULT=$(snmpget -v2c -c public -Ovq "$HOST:$PORT" "$GET")

if [ "$RESULT" != "At flying circus" ]; then
  CODE=11
fi

# SNMPv2c - GetNext
RESULT=$(snmpgetnext -v2c -c public -Ovq "$HOST:$PORT" "$GET")

if [ "$RESULT" != "72" ]; then
  CODE=12
fi

# SNMPv3 - Get - Need to fail
snmpget -v3 -Ovq -u "$SNMP_V3_USER" -l noAuthNoPriv \
  "$HOST:$PORT" "$GET" >/dev/null 2>&1

if [ $? -eq 0 ]; then
  CODE=13
fi

# Stop Container
docker stop -t 1 "$CONTAINER_NAME"

sleep 2

##############################
# SNMPv3 NO auth and NO priv #
##############################

# TODO: Add test for SNMPv3 with noAuthNoPriv

################################
# SNMPv3 with auth and NO priv #
################################

SNMP_V3_AUTH_PROTOCOL="SHA"
SNMP_V3_AUTH_PWD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)

docker run --rm --name "$CONTAINER_NAME" -p "$PORT:161/udp" -d \
  -e SNMP_V3_USER=$SNMP_V3_USER \
  -e SNMP_V3_AUTH_PROTOCOL=$SNMP_V3_AUTH_PROTOCOL \
  -e SNMP_V3_AUTH_PWD=$SNMP_V3_AUTH_PWD \
  "$IMAGE_NAME"

sleep 2

# SNMPv3 - Walk
snmpwalk -v3 -On -u "$SNMP_V3_USER" \
  -l authNoPriv \
  -a "$SNMP_V3_AUTH_PROTOCOL" \
  -A "$SNMP_V3_AUTH_PWD" \
  "$HOST:$PORT" "$WALK" >/dev/null 2>&1

if [ $? -ne 0 ]; then
  CODE=30
fi

# SNMPv3 - Get
RESULT=$(snmpget -v3 -Ovq -u "$SNMP_V3_USER" \
  -l authNoPriv \
  -a "$SNMP_V3_AUTH_PROTOCOL" \
  -A "$SNMP_V3_AUTH_PWD" \
  "$HOST:$PORT" "$GET")

if [ "$RESULT" != "At flying circus" ]; then
  CODE=31
fi

# SNMPv3 - GetNext
RESULT=$(snmpgetnext -v3 -Ovq -u "$SNMP_V3_USER" \
  -l authNoPriv \
  -a "$SNMP_V3_AUTH_PROTOCOL" \
  -A "$SNMP_V3_AUTH_PWD" \
  "$HOST:$PORT" "$GET")

if [ "$RESULT" != "72" ]; then
  CODE=32
fi

# Stop Container
docker stop -t 1 "$CONTAINER_NAME"

sleep 2

#####################################
# SNMPv3 with auth and with privacy #
#####################################

SNMP_V3_PRIV_PROTOCOL="AES"
SNMP_V3_PRIV_PWD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)

docker run --rm --name "$CONTAINER_NAME" -p "$PORT:161/udp" -d \
  -e SNMP_V3_USER=$SNMP_V3_USER \
  -e SNMP_V3_AUTH_PROTOCOL=$SNMP_V3_AUTH_PROTOCOL \
  -e SNMP_V3_AUTH_PWD=$SNMP_V3_AUTH_PWD \
  -e SNMP_V3_PRIV_PROTOCOL=$SNMP_V3_PRIV_PROTOCOL \
  -e SNMP_V3_PRIV_PWD=$SNMP_V3_PRIV_PWD \
  "$IMAGE_NAME"

sleep 2

# SNMPv3 - Walk
snmpwalk -v3 -On -u "$SNMP_V3_USER" \
  -l authPriv \
  -a "$SNMP_V3_AUTH_PROTOCOL" \
  -A "$SNMP_V3_AUTH_PWD" \
  -x "$SNMP_V3_PRIV_PROTOCOL" \
  -X "$SNMP_V3_PRIV_PWD" \
  "$HOST:$PORT" "$WALK" >/dev/null 2>&1

if [ $? -ne 0 ]; then
  CODE=40
fi

# SNMPv3 - Get
RESULT=$(snmpget -v3 -Ovq -u "$SNMP_V3_USER" \
  -l authPriv \
  -a "$SNMP_V3_AUTH_PROTOCOL" \
  -A "$SNMP_V3_AUTH_PWD" \
  -x "$SNMP_V3_PRIV_PROTOCOL" \
  -X "$SNMP_V3_PRIV_PWD" \
  "$HOST:$PORT" "$GET")

if [ "$RESULT" != "At flying circus" ]; then
  CODE=41
fi

# SNMPv3 - GetNext
RESULT=$(snmpgetnext -v3 -Ovq -u "$SNMP_V3_USER" \
  -l authPriv \
  -a "$SNMP_V3_AUTH_PROTOCOL" \
  -A "$SNMP_V3_AUTH_PWD" \
  -x "$SNMP_V3_PRIV_PROTOCOL" \
  -X "$SNMP_V3_PRIV_PWD" \
  "$HOST:$PORT" "$GET")

if [ "$RESULT" != "72" ]; then
  CODE=42
fi

# Stop container
docker stop -t 1 "$CONTAINER_NAME"

sleep 2

################
# Remove Image #
################

docker image rm "$IMAGE_NAME"

exit $CODE
