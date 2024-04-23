#! /bin/bash

# set -e
# set -x

code=0

docker build . --no-cache -t snmpd-container-test

docker run --rm --name snmpd -p 5161:161/udp -d snmpd-container-test

sleep 2

snmpwalk -v 2c -c public localhost:5161 .1.3.6.1.2.1.1

location=$(snmpget -v2c -c public -Ovq localhost:5161 .1.3.6.1.2.1.1.6.0)

if [ "$location" != "At flying circus" ]; then
    echo "Location is not correct."
    code=10
fi

services=$(snmpgetnext -v2c -c public -Ovq localhost:5161 .1.3.6.1.2.1.1.6.0)

if [ "$services" != "72" ]; then
    echo "Services is not correct."
    code=11
fi

docker stop -t 1 snmpd

docker image rm snmpd-container-test

exit $code
