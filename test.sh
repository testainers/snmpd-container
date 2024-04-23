#! /bin/bash
set -e
set -x

docker build . --no-cache -t snmpd-container-test

docker run --rm --name snmpd -p 5161:161/udp -d snmpd-container-test

sleep 2

snmpwalk -v 2c -c public localhost:5161 .

docker stop -t 1 snmpd

docker image rm snmpd-container-test
