#!/bin/sh

echo "ENTRYPOINT"

### Start snmpd.
/usr/sbin/snmpd -f -Lo -C -c /etc/snmp/snmpd.conf
