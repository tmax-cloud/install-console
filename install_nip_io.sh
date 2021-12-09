#!/bin/bash

# hyperauth.org 도메인 이름을 다른 이름으로 변경해서 사용 예) export HYPERAUTH=auth.tmaxcloudauth.org
export HYPERAUTH=172.23.4.209:8443
export SERVICE_TYPE=LoadBalancer
export GATEWAY_TLS=nip_io
#export DOMAIN_NAME=

make folder.deploy
make init.deploy
sleep 10
make traefik.deploy
sleep 30
#export DNS=$(kubectl get svc -n api-gateway-system api-gateway -o=jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io
make tls.deploy
make console.deploy
make ingressroute.deploy
