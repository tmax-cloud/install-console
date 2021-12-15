#!/bin/bash

# hyperauth.org 도메인 이름을 다른 이름으로 변경해서 사용 예) export HYPERAUTH=auth.tmaxcloudauth.org
#export HYPERAUTH=172.23.4.209:8443
#export SERVICE_TYPE=LoadBalancer
#export DEFAULT_TLS_TYPE=nip_io

make dir.build
make init.build
make init.apply 
sleep 10
make traefik.build 
make traefik.apply 
sleep 30
make tls.build 
make tls.apply
make jwt.build
make jwt.apply
make console.build 
make console.apply 
make ingressroute.build
make ingressroute.apply 
