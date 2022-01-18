#working directory
DIR ?= temp
include Makefile.properties

dir.build:
	mkdir ./$(DIR)
dir.clean:
	rm -rf ./$(DIR)

init.build: kustomize
	cp -r manifest/00_INIT $(DIR)/00_INIT
	$(KUSTOMIZE) build --reorder none ./$(DIR)/00_INIT/base > ./$(DIR)/00_init.yaml
init.apply: 
	kubectl apply -f ./$(DIR)/00_init.yaml
init.delete:
	kubectl delete -f ./$(DIR)/00_init.yaml
init.clean:
	rm -rf ./$(DIR)/00_init.yaml
	rm -rf ./$(DIR)/00_INIT

traefik.build: kustomize
	cp -r manifest/01_TRAEFIK $(DIR)/01_TRAEFIK
	cd ./$(DIR)/01_TRAEFIK/base && $(KUSTOMIZE) edit set image traefik=${TRAEFIK_IMG}
ifeq ($(SERVICE_TYPE), LoadBalancer)
	$(KUSTOMIZE) build --reorder none ./$(DIR)/01_TRAEFIK/base > ./$(DIR)/01_traefik.yaml
else ifeq ($(SERVICE_TYPE), NodePort)
	find ./$(DIR)/01_TRAEFIK/overlays/nodeport -name "*.yaml" -exec perl -pi -e 's/\{\{DASHBOARD_PORT\}\}/$(DASHBOARD_PORT)/g' {} \;
	find ./$(DIR)/01_TRAEFIK/overlays/nodeport -name "*.yaml" -exec perl -pi -e 's/\{\{HTTP_PORT\}\}/$(HTTP_PORT)/g' {} \;
	find ./$(DIR)/01_TRAEFIK/overlays/nodeport -name "*.yaml" -exec perl -pi -e 's/\{\{HTTPS_PORT\}\}/$(HTTPS_PORT)/g' {} \;
	find ./$(DIR)/01_TRAEFIK/overlays/nodeport -name "*.yaml" -exec perl -pi -e 's/\{\{K8S_PORT\}\}/$(K8S_PORT)/g' {} \;
	$(KUSTOMIZE) build --reorder none ./$(DIR)/01_TRAEFIK/overlays/nodeport > ./$(DIR)/01_traefik.yaml
else
	$(KUSTOMIZE) build --reorder none ./$(DIR)/01_TRAEFIK/overlays/clusterip > ./$(DIR)/01_traefik.yaml
endif
traefik.apply:
	kubectl apply -f ./$(DIR)/01_traefik.yaml
traefik.delete:
	kubectl delete -f ./$(DIR)/01_traefik.yaml
traefik.clean:
	rm -rf ./$(DIR)/01_traefik.yaml
	rm -rf ./$(DIR)/01_TRAEFIK

tls.build: kustomize
	cp -r manifest/02_TLS $(DIR)/02_TLS
ifeq ($(DEFAULT_TLS_TYPE), acme)
ifeq	($(DOMAIN_NAME),)
	@echo "Error: DOMAIN_NAME is empty"
	exit 1
else
	find ./$(DIR)/02_TLS/acme -name "*.yaml" -exec perl -pi -e 's/\{\{EMAIL\}\}/$(EMAIL)/g' {} \;
	find ./$(DIR)/02_TLS/acme -name "*.yaml" -exec perl -pi -e 's/\{\{ACCESS_KEY_ID\}\}/$(ACCESS_KEY_ID)/g' {} \;
	find ./$(DIR)/02_TLS/acme -name "secret_access_key" -exec perl -pi -e 's/\{\{SECRET_ACCESS_KEY\}\}/$(SECRET_ACCESS_KEY)/g' {} \;
	find ./$(DIR)/02_TLS/acme -name "*.yaml" -exec perl -pi -e 's/\{\{DOMAIN_NAME\}\}/$(DOMAIN_NAME)/g' {} \;
	$(KUSTOMIZE) build --reorder none ./$(DIR)/02_TLS/acme > ./$(DIR)/02_tls_acme.yaml
endif
else ifeq ($(DEFAULT_TLS_TYPE), nip_io)
	find ./$(DIR)/02_TLS/nip_io -name "*.yaml" -exec perl -pi -e 's/\{\{TRAEFIK_IP\}\}/$(TRAEFIK_IP)/g' {} \;
	$(KUSTOMIZE) build --reorder none ./$(DIR)/02_TLS/nip_io > ./$(DIR)/02_tls_nip_io.yaml
else ifeq ($(DEFAULT_TLS_TYPE), selfsigned)
ifeq	($(DOMAIN_NAME),)
	@echo "Error: DOMAIN_NAME is empty"
	exit 1
else
	find ./$(DIR)/02_TLS/selfsigned -name "*.yaml" -exec perl -pi -e 's/\{\{DOMAIN_NAME\}\}/$(DOMAIN_NAME)/g' {} \;
	$(KUSTOMIZE) build --reorder none ./$(DIR)/02_TLS/selfsigned > ./$(DIR)/02_tls_selfsigned.yaml
endif
else ifeq ($(DEFAULT_TLS_TYPE), none)
	@echo "Use the default tls created by Traefik which generated automatically."
else 
	@echo "Must be one of (acme, nip_io, selfsigned, none)"
	exit
endif
tls.apply:
ifeq ($(DEFAULT_TLS_TYPE), acme)
	kubectl apply -f ./$(DIR)/02_tls_acme.yaml
else ifeq ($(DEFAULT_TLS_TYPE), nip_io)
	kubectl apply -f ./$(DIR)/02_tls_nip_io.yaml
else ifeq ($(DEFAULT_TLS_TYPE), selfsigned)
	kubectl apply -f ./$(DIR)/02_tls_selfsigned.yaml
else ifeq ($(DEFAULT_TLS_TYPE), none)
	@echo "Use the default tls created by Traefik which generated automatically."
else
	@echo "Error: Must be one of (acme, nip_io, selfsigned, none)"
	exit 1
endif
tls.delete:
ifeq ($(DEFAULT_TLS_TYPE), acme)
	kubectl delete -f ./$(DIR)/02_tls_acme.yaml
else ifeq ($(DEFAULT_TLS_TYPE), nip_io)
	kubectl delete -f ./$(DIR)/02_tls_nip_io.yaml
else ifeq ($(DEFAULT_TLS_TYPE), selfsigned)
	kubectl delete -f ./$(DIR)/02_tls_selfsigned.yaml
else
	@cho "Error: Must be one of (acme, nip_io, selfsigned, none)"
	exit 1
endif
tls.clean:
	rm -rf ./$(DIR)/02_tls_*.yaml
	rm -rf ./$(DIR)/02_TLS

jwt.build: kustomize
	cp -r manifest/03_JWT_DECODE $(DIR)/03_JWT_DECODE
	find ./$(DIR)/03_JWT_DECODE -name "*.yaml" -exec perl -pi -e 's/\{\{HYPERAUTH\}\}/$(HYPERAUTH)/g' {} \;
	find ./$(DIR)/03_JWT_DECODE -name "*.yaml" -exec perl -pi -e 's/\{\{REALM\}\}/$(REALM)/g' {} \;
	cd ./$(DIR)/03_JWT_DECODE/base && $(KUSTOMIZE) edit set image tmaxcloudck/jwt-decode=${JWT_IMG}
	$(KUSTOMIZE) build --reorder none ./$(DIR)/03_JWT_DECODE/base > ./$(DIR)/03_jwt_decode.yaml
jwt.apply:
	kubectl apply -f ./$(DIR)/03_jwt_decode.yaml
jwt.delete:
	kubectl delete -f ./$(DIR)/03_jwt_decode.yaml
jwt.clean:
	rm -rf ./$(DIR)/03_jwt_decode.yaml
	rm -rf ./$(DIR)/03_JWT_DECODE

console.build: kustomize
	cp -r manifest/04_CONSOLE $(DIR)/04_CONSOLE
	find ./$(DIR)/04_CONSOLE -name "*.yaml" -exec perl -pi -e 's/\{\{HYPERAUTH\}\}/$(HYPERAUTH)/g' {} \;
	find ./$(DIR)/04_CONSOLE -name "*.yaml" -exec perl -pi -e 's/\{\{CLIENT_ID\}\}/$(CLIENT_ID)/g' {} \;
	find ./$(DIR)/04_CONSOLE -name "*.yaml" -exec perl -pi -e 's/\{\{REALM\}\}/$(REALM)/g' {} \;
	find ./$(DIR)/04_CONSOLE -name "*.yaml" -exec perl -pi -e 's/\{\{MC_MODE\}\}/$(MC_MODE)/g' {} \;
	cd ./$(DIR)/04_CONSOLE/base && $(KUSTOMIZE) edit set image tmaxcloudck/hypercloud-console=${CONSOLE_IMG}
	$(KUSTOMIZE) build --reorder none ./$(DIR)/04_CONSOLE/base > ./$(DIR)/04_console.yaml
console.apply:
	kubectl apply -f ./$(DIR)/04_console.yaml
console.delete:
	kubectl delete -f ./$(DIR)/04_console.yaml
console.clean:
	rm -rf ./$(DIR)/04_console.yaml
	rm -rf ./$(DIR)/04_CONSOLE

ingressroute.build: kustomize
	cp -r manifest/04_INGRESSROUTE $(DIR)/04_INGRESSROUTE
	find ./$(DIR)/04_INGRESSROUTE -name "*.yaml" -exec perl -pi -e 's/\{\{CONSOLE\}\}/$(CONSOLE)/g' {} \;	
ifeq ($(DEFAULT_TLS_TYPE), nip_io)
	$(KUSTOMIZE) build --reorder none ./$(DIR)/04_INGRESSROUTE/nip_io > ./$(DIR)/04_ingressroute.yaml
else ifeq ($(DEFAULT_TLS_TYPE), acme)
ifeq	($(DOMAIN_NAME),)
	@echo "Error: DOMAIN_NAME is empty"
	exit 1
else
	find ./$(DIR)/04_INGRESSROUTE/base -name "*.yaml" -exec perl -pi -e 's/\{\{DOMAIN_NAME\}\}/$(DOMAIN_NAME)/g' {} \;	
	$(KUSTOMIZE) build --reorder none ./$(DIR)/04_INGRESSROUTE/base > ./$(DIR)/04_ingressroute.yaml
endif
else ifeq ($(DEFAULT_TLS_TYPE), selfsigned)
ifeq	($(DOMAIN_NAME),)
	@echo "Error: DOMAIN_NAME is empty"
	exit 1
else
	find ./$(DIR)/04_INGRESSROUTE/base -name "*.yaml" -exec perl -pi -e 's/\{\{DOMAIN_NAME\}\}/$(DOMAIN_NAME)/g' {} \;	
	$(KUSTOMIZE) build --reorder none ./$(DIR)/04_INGRESSROUTE/base > ./$(DIR)/04_ingressroute.yaml
endif
else ifeq ($(DEFAULT_TLS_TYPE), none)
ifeq	($(DOMAIN_NAME),)
	$(KUSTOMIZE) build --reorder none ./$(DIR)/04_INGRESSROUTE/none_host > ./$(DIR)/04_ingressroute.yaml
else
	find ./$(DIR)/04_INGRESSROUTE/base -name "*.yaml" -exec perl -pi -e 's/\{\{DOMAIN_NAME\}\}/$(DOMAIN_NAME)/g' {} \;	
	$(KUSTOMIZE) build --reorder none ./$(DIR)/04_INGRESSROUTE/base > ./$(DIR)/04_ingressroute.yaml
endif
else
	@cho "Error: Must be one of (acme, nip_io, selfsigned, none)"
	exit 1
endif
ingressroute.apply:
	kubectl apply -f ./$(DIR)/04_ingressroute.yaml
ingressroute.delete:
	kubectl delete -f ./$(DIR)/04_ingressroute.yaml
ingressroute.clean:
	rm -rf ./$(DIR)/04_ingressroute.yaml
	rm -rf ./$(DIR)/04_INGRESSROUTE