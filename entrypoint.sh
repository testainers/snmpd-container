#!/bin/sh

echo "ENTRYPOINT"

create_user() {
  echo "Creating SNMPv3 user $SNMP_V3_USER with NO auth and NO priv"

  echo "$SNMP_V3_USER_TYPE $SNMP_V3_USER" >'/usr/share/snmp/snmpd.conf'
}

create_user_auth() {
  echo "Creating SNMPv3 user $SNMP_V3_USER with auth $SNMP_V3_AUTH_PROTOCOL and NO priv"

  echo "createUser $SNMP_V3_USER $SNMP_V3_AUTH_PROTOCOL \"$SNMP_V3_AUTH_PWD\"" \
    >'/var/lib/net-snmp/snmpd.conf'

  echo "$SNMP_V3_USER_TYPE $SNMP_V3_USER" >'/usr/share/snmp/snmpd.conf'
}

create_user_auth_priv() {
  echo "Creating SNMPv3 user $SNMP_V3_USER with auth $SNMP_V3_AUTH_PROTOCOL and priv $SNMP_V3_PRIV_PROTOCOL"

  echo "createUser $SNMP_V3_USER $SNMP_V3_AUTH_PROTOCOL \"$SNMP_V3_AUTH_PWD\" $SNMP_V3_PRIV_PROTOCOL \"$SNMP_V3_PRIV_PWD\"" \
    >'/var/lib/net-snmp/snmpd.conf'

  echo "$SNMP_V3_USER_TYPE $SNMP_V3_USER priv" >'/usr/share/snmp/snmpd.conf'
}

if [ -z "$SNMP_COMMUNITY" ]; then
  export SNMP_COMMUNITY="public"
fi

if [ -z "$SNMP_V3_USER_TYPE" ]; then
  export SNMP_V3_USER_TYPE="rouser"
fi

if [ "$SNMP_V3_USER_TYPE" != "rwuser" ] && [ "$SNMP_V3_USER_TYPE" != "rouser" ]; then
  echo "SNMP_V3_USER_TYPE is not correct"
  echo "Updating from '$SNMP_V3_USER_TYPE' to 'rouser'"
  export SNMP_V3_USER_TYPE="rouser"
fi

if [ -z "$SNMP_V3_AUTH_PROTOCOL" ]; then
  export SNMP_V3_AUTH_PROTOCOL="SHA"
fi

if [ -z "$SNMP_V3_PRIV_PROTOCOL" ]; then
  export SNMP_V3_PRIV_PROTOCOL="AES"
fi

if [ -n "$SNMP_V3_USER" ]; then
  if [ -n "$SNMP_V3_AUTH_PWD" ]; then
    if [ -n "$SNMP_V3_PRIV_PWD" ]; then
      create_user_auth_priv
    else
      echo "SNMP_V3_PRIV_PWD is not set"
      create_user_auth
    fi
  else
    echo "SNMP_V3_AUTH_PWD is not set"
    create_user
  fi
else
  echo "SNMP_V3_USER is not set"
  echo "User not created"
fi

envsubst <'/etc/snmp/snmpd.template.conf' >'/etc/snmp/snmpd.conf'

rm -f '/etc/snmp/snmpd.template.conf'

### Start snmpd.
# /usr/sbin/snmpd -f -Lo -C -c /etc/snmp/snmpd.conf
/usr/sbin/snmpd -f -Lo
