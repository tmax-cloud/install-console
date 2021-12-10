
# API-GATEWAY 설치 가이드

## Contents
- [구성 요소](#구성-요소)
- [Prerequisites](#prerequisites)
- [설치 가이드](#설치-방법)
- [Step 0. INIT](#step-1-crd-생성)
- [Step 1. TRAEFIK](#step-2-namespace-serviceaccount-clusterrole-clusterrolebinding-생성)
- [Step 2. TLS](#step-3-job으로-secret-tls-생성)
- [Step 3. CONSOLE](#step-4-service-load-balancer-생성)
- [Step 4. INGRESSROUTE](#step-5-deployment-with-pod-template-생성)
- [Step 5. 동작 확인](#step-6-동작-확인)
- [삭제 가이드](#삭제-가이드)
- [설치 리소스 제거](#설치-리소스-제거)

## 구성 요소
* traefik ([traefik/traefik](https://hub.docker.com/r/library/traefik/tags))
* hypercloud-console ([tmaxcloudck/hypercloud-console](https://hub.docker.com/r/tmaxcloudck/hypercloud-console/tags))
* jwt-decode ([tmaxcloudck/jwd-decode](https://hub.docker.com/r/tmaxcloudck/jwt-decode/tags))
* 가이드 작성 시점(2021/12/09) 최신 버전은 아래와 같습니다. 
    * traefik:v2.5.4
    * hypercloud-console:5.0.41.0
    * jwt-decode:5.1.0.1

## Prerequisites
* Kubernetes, cert-manager, hyperauth (Keycloak), HyperCloud api servier, Prometheus가 설치되어 있어야 합니다.
* 온전한 화면을 위해 추가로 grafana, istio(Kiali, Jaeger), kibana, kubeflow, gitlab 설치가 추가로 필요합니다.
* 추가 모듈은 모두 인그레스로 생성되어 있어야합니다.
* LoadBalancer 타입에 사용할 IP 여유분이 1개 있어야합니다. 
  * IP 여유분이 없을 경우 NodePort 타입으로 서비스를 생성해야합니다. (이 경우, ingress 조회 시 address가 나오지 않습니다.)

## 설치 방법
* Makefile.properties 안의 변수를 설정한다. 
  * 변수에 대한 설정은 [환경 변수](#환경-변수)를 참고해주세요. 
* make 명령어를 사용해 필요한 모듈을 설치합니다.
  * 설치 순서는 [설치 순서(#설치-순서)]를 참고해주세요. 

### 환경 변수
* GATEWAY의 서비스 타입 변수

이름 | 내용 | 기본값  
| --- | --- | ---
| SERVICE_TYPE | GATEWAY 의 서비스 타입 (LoadBalancer, NodePort, ClusterIP) | LoadBalancer 

* GATEWAY의 기본 TLS 인증서 생성에 필요한 변수

이름 | 내용 | 기본값
| --- | --- | ---
| DEFAULT_TLS_TYPE | GATEWAY 의 기본 TLS 인증서 타입 (acme, nip_io, selfsigned, none) | selfsigned 
| DOMAIN_NAME | GATEWAY 의 도메인 이름 설정 | localhost 
| EMAIL | DEFAULT_TLS_TYPE=acme 로 설정했을 때 acme 프로토콜에 필요한 메일 주소 (도메인 발급 기관은 aws route53)| tmaxcloud\@tmax.co.kr 
| ACCESS_KEY_ID | DEFAULT_TLS_TYPE=acme 로 설정했을 때 acme 프로토콜에 필요한 ACCESS_KEY_ID (도메인 발급 기관은 aws route53) | NULL 
| SECRET_ACCESS_KEY | DEFAULT_TLS_TYPE=acme 로 설정했을 때 acme 프로토콜에 필요한 SECRET_ACCESS_KEY (도메인 발급 기관은 aws route53) | NULL

* GATEWAY에 필요한 이미지 설정 변수

이름 | 내용 | 기본값
| --- | --- | ---
| REGISTRY | 이미지 저장소 | docker.io
| TRAEFIK_VERSION | gateway의 핵심 모듈인 traefik 이미지 버전 | v.2.5.4 
| CONSOLE_VERSION | hypercloud-console 이미지 버전 | 5.0.40.0
| JWT_VERSION | jwt 토큰 검증에 상요되는 이미지 버전 | 5.0.0.1 

* HYPERAUTH와 연결에 사용되는 변수

이름 | 내용 | 기본값
| --- | --- | ---
| HYPERAUTH | hyperauth 주소 | hyperauth.org 
| REALM | token 발급에 필요한 realm 이름 | tmax  
| CLIENT_ID | token 발급에 필요한 client id 이름 | hypercloud5 

* CONSOLE 설정 변수

이름 | 내용 | 기본값
| --- | --- | ---
| HYPERAUTH | hyperauth 주소 | hyperauth.org
| REALM | token 발급에 필요한 realm 이름 | tmax
| CLIENT_ID | token 발급에 필요한 client id 이름 | hypercloud5

## 설치 순서 

[comment]: <> (1. make dir.build)

[comment]: <> (  * 설치에 사용될 경로 생성 )

[comment]: <> (2. make init.build)

[comment]: <> (   * namespace, traefik crd, ca 인증서 yaml 파일 생성 )

[comment]: <> (3. make init.apply )
   