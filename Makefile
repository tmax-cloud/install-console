#working directory
DIR ?= temp
include Makefile.properties

folder.deploy:
	@{ \
	mkdir $(DIR) 2>/dev/null ;\
	cp -r manifest/* $(DIR) 2> /dev/null ;\
	}
	find ./$(DIR) -name "*.yaml" -exec perl -pi -e 's/{{HYPERAUTH}}/$(HYPERAUTH)/g' {} \;
	find ./$(DIR) -name "*.yaml" -exec perl -pi -e 's/{{CLIENTID}}/$(CLIENTID)/g' {} \;
	find ./$(DIR) -name "*.yaml" -exec perl -pi -e 's/{{REALM}}/$(REALM)/g' {} \;
	find ./$(DIR) -name "*.yaml" -exec perl -pi -e 's/{{CONSOLE}}/$(CONSOLE)/g' {} \;
folder.clean:
	@{ \
	rm -rf ./$(DIR) > /dev/null ;\
	}

init.build:
	cp -r manifest/00_INIT $(DIR)
	$(KUSTOMIZE) build --reorder none ./$(DIR)/00_INIT/base > ./$(DIR)/00_init.yaml
init.apply: 
	kubectl apply -f ./$(DIR)/00_init.yaml
init.delete:
	kubectl delete -f ./$(DIR)/00_intit.yaml
init.clean:
	rm -rf ./$(DIR)/00_init.yaml

traefik.build: kustomize
	cp -r manifest/01_TRAEFIK $(DIR)
	find ./$(DIR)/01_TRAEFIK -name "*.yaml" -exec perl -pi -e 's/{{HYPERAUTH}}/$(HYPERAUTH)/g' {} \;
	find ./$(DIR)/01_TRAEFIK -name "*.yaml" -exec perl -pi -e 's/{{REALM}}/$(REALM)/g' {} \;
	cd ./$(DIR)/01_TRAEFIK/base && $(KUSTOMIZE) edit set image traefik=${TRAEFIK_IMG}
	cd ./$(DIR)/01_TRAEFIK/base && $(KUSTOMIZE) edit set image tmaxcloudck/jwt-decode=${JWT_IMG}
ifeq ($(SERVICE_TYPE), LoadBalancer)
	$(KUSTOMIZE) build --reorder none ./$(DIR)/01_TRAEFIK/base > ./$(DIR)/01_traefik.yaml
else ifeq ($(SERVICE_TYPE), NodePort)
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

tls.build: kustomize
	cp -r manifest/02_TLS $(DIR)
ifeq ($(DEFAULT_TLS_TYPE), acme)
	find ./$(DIR)/02_TLS/acme -name "*.yaml" -exec perl -pi -e 's/{{EMAIL}}/$(EMAIL)/g' {} \;
	find ./$(DIR)/02_TLS/acme -name "*.yaml" -exec perl -pi -e 's/{{ACCESS_KEY_ID}}/$(ACCESS_KEY_ID)/g' {} \;
	find ./$(DIR)/02_TLS/acme -name "secret_access_key" -exec perl -pi -e 's/{{SECRET_ACCESS_KEY}}/$(SECRET_ACCESS_KEY)/g' {} \;
	find ./$(DIR)/02_TLS/acme -name "*.yaml" -exec perl -pi -e 's/{{DOMAIN_NAME}}/$(DOMAIN_NAME)/g' {} \;
	$(KUSTOMIZE) build --reorder none ./$(DIR)/02_TLS/overlays/acme > ./$(DIR)/02_tls_acme.yaml
else ifeq ($(DEFAULT_TLS_TYPE), nip_io)
	find ./$(DIR)/02_TLS/nip_io -name "*.yaml" -exec perl -pi -e 's/{{DOMAIN_NAME}}/$(TRAEFIK_IP).nip.io/g' {} \;
	$(KUSTOMIZE) build --reorder none ./$(DIR)/02_TLS/overlays/nip_io > ./$(DIR)/02_tls_nip_io.yaml
else ifeq ($(DEFALUT_TLS_TYPE), selfsigned)
	find ./$(DIR)/ -name "*.yaml" -exec perl -pi -e 's/{{DOMAIN_NAME}}/$(DOMAIN_NAME)/g' {} \;
	$(KUSTOMIZE) build --reorder none ./$(DIR)/02_TLS/overlays/selfsigned > ./$(DIR)/02_tls_selfsigned.yaml
else
	find ./$(DIR)/ -name "*.yaml" -exec perl -pi -e 's/{{DOMAIN_NAME}}/$(DOMAIN_NAME)/g' {} \;
	echo "Use the default tls created by Traefik which generated automatically."
endif
tls.apply:
ifeq ($(DEFAULT_TLS_TYPE), acme)
	kubectl apply -f ./$(DIR)/02_tls_acme.yaml
else ifeq ($(DEFALUT_TLS_TYPE), nip_io)
	kubectl apply -f ./$(DIR)/02_tls_nip_io.yaml
else ifeq ($(DEFAULT_TLS_TYPE), selfsigned)
	kubectl apply -f ./$(DIR)/02_tls_selfsigned.yaml
else
endif
tls.delete:
ifeq ($(GATEWAY_TLS), acme)
	kubectl delete -f ./$(DIR)/02_tls_acme.yaml
else
	kubectl delete -f ./$(DIR)/02_tls_selfsigned.yaml
endif
tls.clean:
ifeq ($(GATEWAY_TLS), acme)
	rm -rf ./$(DIR)/02_tls_acme.yaml
else
	rm -rf ./$(DIR)/02_tls_selfsigned.yaml
endif

console.deploy: kustomize
	cd ./$(DIR)/03_CONSOLE/base && $(KUSTOMIZE) edit set image tmaxcloudck/hypercloud-console=${CONSOLE_IMG}
	$(KUSTOMIZE) build --reorder none ./$(DIR)/03_CONSOLE/base > ./$(DIR)/03_console.yaml
	kubectl apply -f ./$(DIR)/03_console.yaml
console.teardown:
	kubectl delete -f ./$(DIR)/03_console.yaml
console.clean:
	rm -rf ./$(DIR)/03_console.yaml

ingressroute.deploy: kustomize
	$(KUSTOMIZE) build --reorder none ./$(DIR)/04_INGRESSROUTE/base > ./$(DIR)/04_ingressroute.yaml
	kubectl apply -f ./$(DIR)/04_ingressroute.yaml
ingressroute.teardown:
	kubectl delete -f ./$(DIR)/04_ingressroute.yaml
ingressroute.clean:
	rm -rf ./$(DIR)/04_ingressroute.yaml

#get-traefik-ip:
#ifeq ($(type), LoadBalancer)
#TRAEFIK_IP=$(shell kubectl get svc -n api-gateway-system api-gateway -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
#else ifeq ($(type), NodePort)
#TRAEFIK_IP=$(shell kubectl get nodes --selector=node-role.kubernetes.io/master -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
#else
#TRAEFIK_IP=$(shell kubectl get svc -n api-gateway-system api-gateway -o=jsonpath='{.spec.clusterIP}')
#endif
##
#test: # get-traefik-ip
#	-kubectl config use-context team-k8s
#	-kubectl-ns api-gateway-system
#	-kubectl get svc