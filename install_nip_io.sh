#!/bin/bash

make deploy-init
sleep 10
make deploy-traefik
sleep 30
export DNS=$(kubectl get svc -n api-gateway-system api-gateway -o=jsonpath='{.status.loadBalancer.ingress[0].ip}').nip.io
make deploy-tls-self-signed
make deploy-console
make deploy-ingressroute
