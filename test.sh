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

###########
# SNMPv2c #
###########

SNMP_COMMUNITY="tstcmnt"
SNMP_V3_USER="testainers"

echo "Starting SNMPv2c"
docker run -d --rm --name "$CONTAINER_NAME" -p "$PORT:161/udp" \
  -e SNMP_COMMUNITY=$SNMP_COMMUNITY \
  "$IMAGE_NAME" >/dev/null 2>&1
sleep 2

# Testing SNMPv2c - Walk
echo "Testing SNMPv2c - Walk"
if ! snmpwalk -v 2c -c "$SNMP_COMMUNITY" "$HOST:$PORT" "$WALK" >/dev/null 2>&1
then
  CODE=10
  echo "Error $CODE: SNMPv2c Walk"
fi

# Testing SNMPv2c - Get
echo "Testing SNMPv2c - Get"
RESULT=$(snmpget -v2c -c "$SNMP_COMMUNITY" -Ovq "$HOST:$PORT" "$GET" | tr -d '"')

if [ "$RESULT" != "At flying circus" ]; then
  CODE=11
  echo "Error $CODE: $RESULT"
fi

# Testing SNMPv2c - GetNext
echo "Testing SNMPv2c - GetNext"
RESULT=$(snmpgetnext -v2c -c "$SNMP_COMMUNITY" -Ovq "$HOST:$PORT" "$GET")

if [ "$RESULT" != "72" ]; then
  CODE=12
  echo "Error $CODE: $RESULT"
fi

# Testing SNMPv3 - Get - Need to fail
echo "Testing SNMPv3 - Get - Need to fail"

if snmpget -v3 -Ovq -u "$SNMP_V3_USER" -l noAuthNoPriv \
       "$HOST:$PORT" "$GET" >/dev/null 2>&1
then
  CODE=13
  echo "Error $CODE: SNMPv3 - Get - Need to fail"
fi

# Stop Container
echo "Stopping SNMPv2c"
docker stop -t 1 "$CONTAINER_NAME" >/dev/null 2>&1
sleep 2

##############################
# SNMPv3 NO auth and NO priv #
##############################

# TODO: Add test for SNMPv3 with noAuthNoPriv

################################
# SNMPv3 with auth and NO priv #
################################

SNMP_V3_AUTH_PROTOCOL="SHA"
SNMP_V3_AUTH_PWD="a1b2c3d4e5f6"

echo "Starting SNMPv3 with auth and NO priv"
docker run -d --rm --name "$CONTAINER_NAME" -p "$PORT:161/udp" \
  -e SNMP_V3_USER=$SNMP_V3_USER \
  -e SNMP_V3_AUTH_PROTOCOL=$SNMP_V3_AUTH_PROTOCOL \
  -e SNMP_V3_AUTH_PWD=$SNMP_V3_AUTH_PWD \
  "$IMAGE_NAME" >/dev/null 2>&1
sleep 2

# Testing SNMPv3 Walk
echo "Testing SNMPv3 Walk"
if ! snmpwalk -v3 -On -u "$SNMP_V3_USER" \
     -l authNoPriv \
     -a "$SNMP_V3_AUTH_PROTOCOL" \
     -A "$SNMP_V3_AUTH_PWD" \
     "$HOST:$PORT" "$WALK" >/dev/null 2>&1
then
  CODE=30
  echo "Error $CODE: SNMPv3 Walk"
fi

# Testing SNMPv3 Get
echo "Testing SNMPv3 Get"
RESULT=$(snmpget -v3 -Ovq -u "$SNMP_V3_USER" \
  -l authNoPriv \
  -a "$SNMP_V3_AUTH_PROTOCOL" \
  -A "$SNMP_V3_AUTH_PWD" \
  "$HOST:$PORT" "$GET" | tr -d '"')

if [ "$RESULT" != "At flying circus" ]; then
  CODE=31
  echo "Error $CODE: $RESULT"
fi

# Testing SNMPv3 GetNext
echo "Testing SNMPv3 GetNext"
RESULT=$(snmpgetnext -v3 -Ovq -u "$SNMP_V3_USER" \
  -l authNoPriv \
  -a "$SNMP_V3_AUTH_PROTOCOL" \
  -A "$SNMP_V3_AUTH_PWD" \
  "$HOST:$PORT" "$GET")

if [ "$RESULT" != "72" ]; then
  CODE=32
  echo "Error $CODE: $RESULT"
fi

# Stopping SNMPv3 with auth and NO priv
echo "Starting SNMPv3 with auth and NO priv"
docker stop -t 1 "$CONTAINER_NAME" >/dev/null 2>&1
sleep 2

#####################################
# SNMPv3 with auth and with privacy #
#####################################

SNMP_V3_PRIV_PROTOCOL="AES"
SNMP_V3_PRIV_PWD="f6e5d4c3b2a1"

echo "Starting SNMPv3 with auth and with privacy"
docker run -d --rm --name "$CONTAINER_NAME" -p "$PORT:161/udp" \
  -e SNMP_V3_USER=$SNMP_V3_USER \
  -e SNMP_V3_AUTH_PROTOCOL=$SNMP_V3_AUTH_PROTOCOL \
  -e SNMP_V3_AUTH_PWD=$SNMP_V3_AUTH_PWD \
  -e SNMP_V3_PRIV_PROTOCOL=$SNMP_V3_PRIV_PROTOCOL \
  -e SNMP_V3_PRIV_PWD=$SNMP_V3_PRIV_PWD \
  "$IMAGE_NAME" >/dev/null 2>&1
sleep 2

# Testing SNMPv3 Walk
echo "Testing SNMPv3 Walk"
if ! snmpwalk -v3 -On -u "$SNMP_V3_USER" \
     -l authPriv \
     -a "$SNMP_V3_AUTH_PROTOCOL" \
     -A "$SNMP_V3_AUTH_PWD" \
     -x "$SNMP_V3_PRIV_PROTOCOL" \
     -X "$SNMP_V3_PRIV_PWD" \
     "$HOST:$PORT" "$WALK" >/dev/null 2>&1
then
  CODE=40
  echo "Error $CODE: SNMPv3 Walk"
fi

# Testing SNMPv3 Get
echo "Testing SNMPv3 Get"
RESULT=$(snmpget -v3 -Ovq -u "$SNMP_V3_USER" \
  -l authPriv \
  -a "$SNMP_V3_AUTH_PROTOCOL" \
  -A "$SNMP_V3_AUTH_PWD" \
  -x "$SNMP_V3_PRIV_PROTOCOL" \
  -X "$SNMP_V3_PRIV_PWD" \
  "$HOST:$PORT" "$GET" | tr -d '"')

if [ "$RESULT" != "At flying circus" ]; then
  CODE=41
  echo "Error $CODE: $RESULT"
fi

# Testing SNMPv3 GetNext
echo "Testing SNMPv3 GetNext"
RESULT=$(snmpgetnext -v3 -Ovq -u "$SNMP_V3_USER" \
  -l authPriv \
  -a "$SNMP_V3_AUTH_PROTOCOL" \
  -A "$SNMP_V3_AUTH_PWD" \
  -x "$SNMP_V3_PRIV_PROTOCOL" \
  -X "$SNMP_V3_PRIV_PWD" \
  "$HOST:$PORT" "$GET")

if [ "$RESULT" != "72" ]; then
  CODE=42
  echo "Error $CODE: $RESULT"
fi

# Stopping SNMPv3 with auth and with privacy
echo "Stopping SNMPv3 with auth and with privacy"
docker stop -t 1 "$CONTAINER_NAME" >/dev/null 2>&1
sleep 2

################
# Remove Image #
################

docker image rm "$IMAGE_NAME" >/dev/null 2>&1

echo "Done"

exit $CODE
