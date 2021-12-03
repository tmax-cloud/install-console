#export version
REGISTRY ?= docker.io
TRAEFIK_VERSION ?= v2.5.4
TRAEFIK_IMG ?= $(REGISTRY)/library/traefik:$(TRAEFIK_VERSION)
CONSOLE_VERSION ?= 5.0.40.0
CONSOLE_IMG ?= $(REGISTRY)/tmaxcloudck/hypercloud-console:$(CONSOLE_VERSION)
JWT_VERSION ?= 5.0.0.1
JWT_IMG ?= $(REGISTRY)/tmaxcloudck/jwt-decode:$(JWT_VERSION)

HYPERAUTH ?= hyperauth.org
DNS ?= tmaxcloud.org
#CONSOLE ?= console

deploy-init:
	kubectl apply -k ./00_INIT/base/

undeploy-init:
	kubectl delete -k ./00_INIT/base/

deploy-traefik: kustomize
	sed -i '' s/@@HYPERAUTH@@/$(HYPERAUTH)/g ./01_GATEWAY/traefik/004_deploy.yaml
	cd 01_GATEWAY/traefik && $(KUSTOMIZE) edit set image traefik=${TRAEFIK_IMG}
	cd 01_GATEWAY/traefik && $(KUSTOMIZE) edit set image tmaxcloudck/jwt-decode=${JWT_IMG}
	$(KUSTOMIZE) build ./01_GATEWAY/traefik/ | kubectl apply -f -
	sed -i '' s/$(HYPERAUTH)/@@HYPERAUTH@@/g ./01_GATEWAY/traefik/004_deploy.yaml

undeploy-traefik:
	kubectl delete -k ./01_GATEWAY/traefik/

## MUST SET DNS BEFORE deploy command below
deploy-console: kustomize
	sed -i '' s/@@HYPERAUTH@@/$(HYPERAUTH)/g ./01_GATEWAY/console/001_deploy.yaml
	#sed -i '' s/@@CONSOLE@@/$(CONSOLE)/g ./01_GATEWAY/console/003_ingressroute.yaml
	sed -i '' s/@@DNS@@/$(DNS)/g ./01_GATEWAY/console/003_ingressroute.yaml
	cd 01_GATEWAY/console && $(KUSTOMIZE) edit set image tmaxcloudck/hypercloud-console=${CONSOLE_IMG}
	$(KUSTOMIZE) build ./01_GATEWAY/console/ # | kubectl apply -f -
	sed -i '' s/$(HYPERAUTH)/@@HYPERAUTH@@/g ./01_GATEWAY/console/001_deploy.yaml
	#sed -i '' s/$(CONSOLE)/@@CONSOLE@@/g ./01_GATEWAY/console/003_ingressroute.yaml
	sed -i '' s/$(DNS)/@@DNS@@/g ./01_GATEWAY/console/003_ingressroute.yaml

undeploy-console:
	kubectl delete -k ./01_GATEWAY/console/

deploy-tls-acme-route53: kustomize
	sed -i '' s/@@DNS@@/$(DNS)/g ./02_GATEWAY_TLS/acme_route53/002_certificate.yaml
	#$(KUSTOMIZE) build ./02_GATEWAY_TLS/acme_route53/
	$(KUSTOMIZE) build ./02_GATEWAY_TLS/acme_route53/ | kubectl apply -f -
	sed -i '' s/$(DNS)/@@DNS@@/g ./02_GATEWAY_TLS/acme_route53/002_certificate.yaml

undeploy-acme-route53:
	kubectl delete -k ./02_GATEWAY_TLS/acme_route53/

deploy-tls-self-signed: kustomize
	sed -i '' s/@@DNS@@/$(DNS)/g ./02_GATEWAY_TLS/self_signed/001_certificate.yaml
	#$(KUSTOMIZE) build ./02_GATEWAY_TLS/self_signed/
	$(KUSTOMIZE) build ./02_GATEWAY_TLS/self_signed/ | kubectl apply -f -
	sed -i '' s/$(DNS)/@@DNS@@/g ./02_GATEWAY_TLS/self_signed/001_certificate.yaml

undeploy-tls-self-signed:
	kubectl delete -k ./02_GATEWAY_TLS/self_signed/

deploy-ingressroute: kustomize
	sed -i '' s/@@DNS@@/$(DNS)/g ./03_INGRESSROUTE/base/*.yaml
	#$(KUSTOMIZE) build ./03_INGRESSROUTE/base/
	$(KUSTOMIZE) build ./03_INGRESSROUTE/base/ | kubectl apply -f -
	sed -i '' s/$(DNS)/@@DNS@@/g ./03_INGRESSROUTE/base/*.yaml

undeploy-ingressroute:
	kubectl delete -k ./03_INGRESSROUTE/base/

kustomize:
ifeq (, $(shell which kustomize 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p bin ;\
	curl -sSLo - https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v3.5.4/kustomize_v3.5.4_$(OS)_$(ARCH).tar.gz | tar xzf - -C bin/ ;\
	}
KUSTOMIZE=$(realpath ./bin/kustomize)
else
KUSTOMIZE=$(shell which kustomize)
endif


#get-ip:
#DNS=$(shell kubectl get svc -n api-gateway-system)
##  	export DNS=$(kubectl get svc -n api-gateway-system api-gateway -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
