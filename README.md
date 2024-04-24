<h1>
<img src="helpers/testainers-100.png" alt="Testainers" title="Testainers">
snmpd-container
</h1>

[![Build With Love](https://img.shields.io/badge/%20built%20with-%20%E2%9D%A4-ff69b4.svg)](https://github.com/testainers/snmpd-container/stargazers)
[![Version](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fapi.github.com%2Frepos%2Ftestainers%2Fsnmpd-container%2Freleases%2Flatest&query=%24.name&label=version&color=orange)](https://hub.docker.com/r/testainers/snmpd-container/tags)
[![Licence](https://img.shields.io/github/license/testainers/snmpd-container?color=blue)](https://github.com/testainers/snmpd-container/blob/main/LICENCE)
[![Build](https://img.shields.io/github/actions/workflow/status/testainers/snmpd-container/main.yml?branch=main)](https://github.com/testainers/snmpd-container/releases/latest)

The small container image is designed specifically for testing SNMP connections.

## Funding

Your contribution will help drive the development of quality tools for the
Flutter and Dart developer community. Any amount will be appreciated.
Thank you for your continued support!

[![BuyMeACoffee](https://www.buymeacoffee.com/assets/img/guidelines/download-assets-sm-2.svg)](https://www.buymeacoffee.com/edufolly)

## PIX

Sua contribuição ajudará a impulsionar o desenvolvimento de ferramentas de
para a co munidade de desenvolvedores Flutter e Dart. Qualquer quantia será
apreciada.
Obrigado pelo seu apoio contínuo!

[![PIX](helpers/pix.png)](https://nubank.com.br/pagar/2bt2q/RBr4Szfuwr)

---

## Environment Variables

| Variable              | Options         | Default |
|-----------------------|-----------------|---------|
| SNMP_V3_USER          | --              | --      |
| SNMP_V3_USER_TYPE     | rouser - rwuser | rouser  |
| SNMP_V3_AUTH_PROTOCOL | MD5 - SHA       | SHA     |
| SNMP_V3_AUTH_PWD      | --              | --      |
| SNMP_V3_PRIV_PROTOCOL | DES - AES       | AES     |
| SNMP_V3_PRIV_PWD      | --              | --      |

## How to Use

```shell
docker run --rm --name snmpd -p 5161:161/udp -d testainers/snmpd-container:latest
```

## How to Connect

```shell
snmpwalk -v2c -c public 127.0.0.1:5161 .
```

---

## Build

```shell
docker build . --no-cache -t snmpd-container
```

## Run

```shell
docker run --rm --name snmpd -p 5161:161/udp -d snmpd-container
```
