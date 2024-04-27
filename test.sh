#! /bin/bash

# set -e
# set -x

CODE=0

# Name of the image
IMAGE_NAME="snmpd-container-test:test"

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
printf "Building Image... "
if docker build . --quiet --no-cache --tag "$IMAGE_NAME" >/dev/null 2>&1
then
  printf "[OK]\n\n"
else
  CODE=1
  printf "[FAIL] %s\n" "$CODE"
  exit $CODE
fi

###########
# SNMPv2c #
###########

SNMP_COMMUNITY="tstcmnt"
SNMP_LOCATION="At home"
SNMP_SERVICES="60"
SNMP_V3_USER="testainers"

printf "Starting SNMPv2c... "
docker run -d --rm --name "$CONTAINER_NAME" -p "$PORT:161/udp" \
  -e SNMP_COMMUNITY="$SNMP_COMMUNITY" \
  -e SNMP_LOCATION="$SNMP_LOCATION" \
  -e SNMP_SERVICES="$SNMP_SERVICES" \
  "$IMAGE_NAME" >/dev/null 2>&1
sleep 2
printf "[OK]\n"

# Testing SNMPv2c Walk
printf "Testing SNMPv2c Walk... "
if snmpwalk -v 2c -c "$SNMP_COMMUNITY" "$HOST:$PORT" "$WALK" >/dev/null 2>&1
then
  printf "[OK]\n"
else
  CODE=10
  printf "[FAIL] %s\n" "$CODE"
fi

# Testing SNMPv2c Get
printf "Testing SNMPv2c Get... "
RESULT=$(snmpget -v2c -c "$SNMP_COMMUNITY" -Ovq "$HOST:$PORT" "$GET" | tr -d '"')

if [ "$RESULT" == "$SNMP_LOCATION" ]; then
  printf "[OK]\n"
else
  CODE=11
  printf "[FAIL] %s\n" "$CODE"
fi

# Testing SNMPv2c GetNext
printf "Testing SNMPv2c GetNext... "
RESULT=$(snmpgetnext -v2c -c "$SNMP_COMMUNITY" -Ovq "$HOST:$PORT" "$GET")

if [ "$RESULT" == "$SNMP_SERVICES" ]; then
  printf "[OK]\n"
else
  CODE=12
  printf "[FAIL] %s\n" "$CODE"
fi

# Testing SNMPv3 - Get - Need to fail
printf "Testing SNMPv3 Get... "

if ! snmpget -v3 -Ovq -u "$SNMP_V3_USER" -l noAuthNoPriv \
       "$HOST:$PORT" "$GET" >/dev/null 2>&1
then
  printf "[OK]\n"
else
  CODE=13
  printf "[FAIL] %s\n" "$CODE"
fi

# Stop Container
printf "Stopping SNMPv2c... "
docker stop -t 1 "$CONTAINER_NAME" >/dev/null 2>&1
sleep 2
printf "[OK]\n\n"

##############################
# SNMPv3 NO auth and NO priv #
##############################

# TODO: Add test for SNMPv3 with noAuthNoPriv

################################
# SNMPv3 with auth and NO priv #
################################

SNMP_V3_AUTH_PROTOCOL="SHA"
SNMP_V3_AUTH_PWD="a1b2c3d4e5f6"

printf "Starting SNMPv3 with auth and NO priv... "
docker run -d --rm --name "$CONTAINER_NAME" -p "$PORT:161/udp" \
  -e SNMP_LOCATION="$SNMP_LOCATION" \
  -e SNMP_SERVICES="$SNMP_SERVICES" \
  -e SNMP_V3_USER="$SNMP_V3_USER" \
  -e SNMP_V3_AUTH_PROTOCOL="$SNMP_V3_AUTH_PROTOCOL" \
  -e SNMP_V3_AUTH_PWD="$SNMP_V3_AUTH_PWD" \
  "$IMAGE_NAME" >/dev/null 2>&1
sleep 2
printf "[OK]\n"

# Testing SNMPv3 Walk
printf "Testing SNMPv3 Walk..."
if snmpwalk -v3 -On -u "$SNMP_V3_USER" \
     -l authNoPriv \
     -a "$SNMP_V3_AUTH_PROTOCOL" \
     -A "$SNMP_V3_AUTH_PWD" \
     "$HOST:$PORT" "$WALK" >/dev/null 2>&1
then
  printf "[OK]\n"
else
  CODE=30
  printf "[FAIL] %s\n" "$CODE"
fi

# Testing SNMPv3 Get
printf "Testing SNMPv3 Get... "
RESULT=$(snmpget -v3 -Ovq -u "$SNMP_V3_USER" \
  -l authNoPriv \
  -a "$SNMP_V3_AUTH_PROTOCOL" \
  -A "$SNMP_V3_AUTH_PWD" \
  "$HOST:$PORT" "$GET" | tr -d '"')

if [ "$RESULT" == "$SNMP_LOCATION" ]; then
  printf "[OK]\n"
else
  CODE=31
  printf "[FAIL] %s\n" "$CODE"
fi

# Testing SNMPv3 GetNext
printf "Testing SNMPv3 GetNext... "
RESULT=$(snmpgetnext -v3 -Ovq -u "$SNMP_V3_USER" \
  -l authNoPriv \
  -a "$SNMP_V3_AUTH_PROTOCOL" \
  -A "$SNMP_V3_AUTH_PWD" \
  "$HOST:$PORT" "$GET")

if [ "$RESULT" == "$SNMP_SERVICES" ]; then
  printf "[OK]\n"
else
  CODE=32
  printf "[FAIL] %s\n" "$CODE"
fi

# Stopping SNMPv3 with auth and NO priv
printf "Stopping SNMPv3 with auth and NO priv... "
docker stop -t 1 "$CONTAINER_NAME" >/dev/null 2>&1
sleep 2
printf "[OK]\n\n"

#####################################
# SNMPv3 with auth and with privacy #
#####################################

SNMP_V3_PRIV_PROTOCOL="AES"
SNMP_V3_PRIV_PWD="f6e5d4c3b2a1"

printf "Starting SNMPv3 with auth and with privacy... "
docker run -d --rm --name "$CONTAINER_NAME" -p "$PORT:161/udp" \
  -e SNMP_LOCATION="$SNMP_LOCATION" \
  -e SNMP_SERVICES="$SNMP_SERVICES" \
  -e SNMP_V3_USER="$SNMP_V3_USER" \
  -e SNMP_V3_AUTH_PROTOCOL="$SNMP_V3_AUTH_PROTOCOL" \
  -e SNMP_V3_AUTH_PWD="$SNMP_V3_AUTH_PWD" \
  -e SNMP_V3_PRIV_PROTOCOL="$SNMP_V3_PRIV_PROTOCOL" \
  -e SNMP_V3_PRIV_PWD="$SNMP_V3_PRIV_PWD" \
  "$IMAGE_NAME" >/dev/null 2>&1
sleep 2
printf "[OK]\n"

# Testing SNMPv3 Walk
printf "Testing SNMPv3 Walk... "
if snmpwalk -v3 -On -u "$SNMP_V3_USER" \
     -l authPriv \
     -a "$SNMP_V3_AUTH_PROTOCOL" \
     -A "$SNMP_V3_AUTH_PWD" \
     -x "$SNMP_V3_PRIV_PROTOCOL" \
     -X "$SNMP_V3_PRIV_PWD" \
     "$HOST:$PORT" "$WALK" >/dev/null 2>&1
then
  printf "[OK]\n"
else
  CODE=40
  printf "[FAIL] %s\n" "$CODE"
fi

# Testing SNMPv3 Get
printf "Testing SNMPv3 Get... "
RESULT=$(snmpget -v3 -Ovq -u "$SNMP_V3_USER" \
  -l authPriv \
  -a "$SNMP_V3_AUTH_PROTOCOL" \
  -A "$SNMP_V3_AUTH_PWD" \
  -x "$SNMP_V3_PRIV_PROTOCOL" \
  -X "$SNMP_V3_PRIV_PWD" \
  "$HOST:$PORT" "$GET" | tr -d '"')

if [ "$RESULT" == "$SNMP_LOCATION" ]; then
  printf "[OK]\n"
else
  CODE=41
  printf "[FAIL] %s\n" "$CODE"
fi

# Testing SNMPv3 GetNext
printf "Testing SNMPv3 GetNext... "
RESULT=$(snmpgetnext -v3 -Ovq -u "$SNMP_V3_USER" \
  -l authPriv \
  -a "$SNMP_V3_AUTH_PROTOCOL" \
  -A "$SNMP_V3_AUTH_PWD" \
  -x "$SNMP_V3_PRIV_PROTOCOL" \
  -X "$SNMP_V3_PRIV_PWD" \
  "$HOST:$PORT" "$GET")

if [ "$RESULT" == "$SNMP_SERVICES" ]; then
  printf "[OK]\n"
else
  CODE=42
  printf "[FAIL] %s\n" "$CODE"
fi

# Stopping SNMPv3 with auth and with privacy
printf "Stopping SNMPv3 with auth and with privacy... "
docker stop -t 1 "$CONTAINER_NAME" >/dev/null 2>&1
sleep 2
printf "[OK]\n\n"

################
# Remove Image #
################

docker image rm "$IMAGE_NAME" >/dev/null 2>&1

printf "Done!\n"

exit $CODE
