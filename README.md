
# API-GATEWAY 설치 가이드

## 구성 요소
* traefik ([traefik/traefik](https://hub.docker.com/r/library/traefik/tags))
* hypercloud-console ([tmaxcloudck/hypercloud-console](https://hub.docker.com/r/tmaxcloudck/hypercloud-console/tags))
* jwt-decode ([tmaxcloudck/jwd-decode](https://hub.docker.com/r/tmaxcloudck/jwt-decode/tags))
* 가이드 작성 시점(2021/12/08) 최신 버전은 아래와 같습니다. 
    * traefik:v2.5.4
    * hypercloud-console:5.0.40.0
    * jwt-decode:5.1.0.1

## Prerequisites
* Kubernetes, cert-manager, hyperauth (Keycloak), HyperCloud api servier, Prometheus가 설치되어 있어야 합니다.
* 온전한 화면을 위해 추가로 grafana, istio(Kiali, Jaeger), kibana, kubeflow, gitlab 설치가 추가로 필요합니다.
* 추가 모듈은 모두 인그레스로 생성되어 있어야합니다.
* LoadBalancer 타입에 사용할 IP 여유분이 1개 있어야합니다. 
  * 추가 IP가 없을 경우 혹은 LoadBalancer 생성이 어려울 경우 NodePort 타입으로 서비스 생성이 되어야합니다. (이 경우, ingress 조회 시 address가 나오지 않음)


[comment]: <> (## 폐쇄망 구축 가이드)

[comment]: <> (* 폐쇄망에서는 Docker Hub의 이미지를 사용할 수 없으므로, 아래의 과정을 통해 이미지를 준비하여야 합니다.)

[comment]: <> (* 이 과정 이후로는 일반적인 Install Steps를 그대로 따르면 됩니다.)

[comment]: <> (    * 작업 디렉토리 생성 및 환경 설정)

[comment]: <> (	  ```bash)

[comment]: <> (	  mkdir -p ~/console-install)

[comment]: <> (      export CONSOLE_HOME=~/console-install )

[comment]: <> (      export CONSOLE_VERSION=5.0.12.0)

[comment]: <> (      export OPERATOR_VERSION=5.1.0.1)

[comment]: <> (      cd $CONSOLE_HOME)

[comment]: <> (	  ```)
	  
[comment]: <> (    * 외부 네트워크 통신이 가능한 환경에서 이미지 다운로드)

[comment]: <> (	  ```bash)

[comment]: <> (	  sudo docker pull  tmaxcloudck/hypercloud-console:${CONSOLE_VERSION})

[comment]: <> (	  sudo docker save tmaxcloudck/hypercloud-console:${CONSOLE_VERSION} > console_${CONSOLE_VERSION}.tar)

[comment]: <> (      	  sudo docker pull  tmaxcloudck/console-operator:${OPERATOR_VERSION})

[comment]: <> (	  sudo docker save tmaxcloudck/hypercloud-console:${OPERATOR_VERSION} > operator_${OPERATOR_VERSION}.tar)

[comment]: <> (	  # tls 인증서 생성을 위한 도커 이미지 )

[comment]: <> (	  sudo docker pull jettech/kube-webhook-certgen:v1.3.0)

[comment]: <> (	  sudo docker save jettech/kube-webhook-certgen:v1.3.0 > certgen_v1.3.0.tar)

[comment]: <> (	  ```)
	  
[comment]: <> (    * tar 파일을 폐쇄망 환경으로 이동시킨 후, registry에 이미지 push)

[comment]: <> (	  ```bash)

[comment]: <> (      # 이미지 레지스트리 주소 )

[comment]: <> (      REGISTRY=[IP:PORT])

[comment]: <> (	  sudo docker load < console_${CONSOLE_VERSION}.tar)

[comment]: <> (	  sudo docker tag tmaxcloudck/hypercloud-console:${CONSOLE_VERSION} ${REGISTRY}/tmaxcloudck/hypercloud-console:${CONSOLE_VERSION})

[comment]: <> (	  sudo docker push ${REGISTRY}/tmaxcloudck/hypercloud-console:${CONSOLE_VERSION})

[comment]: <> (          sudo docker load < operator_${OPERATOR_VERSION}.tar)

[comment]: <> (	  sudo docker tag tmaxcloudck/console-operator:${OPERATOR_VERSION} ${REGISTRY}/tmaxcloudck/console-operator:${OPERATOR_VERSION})

[comment]: <> (	  sudo docker push ${REGISTRY}/tmaxcloudck/console-operator:${OPERATOR_VERSION})
	  
[comment]: <> (	  #tls 인증서 생성을 위한 도커 이미지 로드 )

[comment]: <> (	  sudo docker load < certgen_v1.3.0.tar)

[comment]: <> (	  sudo docker tag jettech/kube-webhook-certgen:v1.3.0 ${REGISTRY}/jettech/kube-webhook-certgen:v1.3.0)

[comment]: <> (	  sudo docker push ${REGISTRY}/jettech/kube-webhook-certgen:v1.3.0)

[comment]: <> (	  ```)

[comment]: <> (## 설치 가이드)

[comment]: <> (- [Console 설치 가이드]&#40;#console-설치-가이드&#41;)

[comment]: <> (  - [구성 요소]&#40;#구성-요소&#41;)

[comment]: <> (  - [Prerequisites]&#40;#prerequisites&#41;)

[comment]: <> (  - [폐쇄망 구축 가이드]&#40;#폐쇄망-구축-가이드&#41;)

[comment]: <> (  - [설치 가이드]&#40;#설치-가이드&#41;)

[comment]: <> (  - [설치 yaml 파일]&#40;#설치-yaml-파일&#41;)

[comment]: <> (  - [Step 1. CRD 생성]&#40;#step-1-crd-생성&#41;)

[comment]: <> (  - [Step 2. Namespace, ServiceAccount, ClusterRole, ClusterRoleBinding 생성]&#40;#step-2-namespace-serviceaccount-clusterrole-clusterrolebinding-생성&#41;)

[comment]: <> (  - [Step 3. Job으로 Secret &#40;TLS&#41; 생성]&#40;#step-3-job으로-secret-tls-생성&#41;)

[comment]: <> (  - [Step 4. Service &#40;Load Balancer&#41; 생성]&#40;#step-4-service-load-balancer-생성&#41;)

[comment]: <> (  - [Step 5. Deployment &#40;with Pod Template&#41; 생성]&#40;#step-5-deployment-with-pod-template-생성&#41;)

[comment]: <> (  - [Step 6. 동작 확인]&#40;#step-6-동작-확인&#41;)

[comment]: <> (  - [삭제 가이드]&#40;#삭제-가이드&#41;)

[comment]: <> (  - [쉘 스크립트로 설치]&#40;#쉘-스크립트로-설치&#41;)

[comment]: <> (  - [쉘 스크립트로 삭제]&#40;#쉘-스크립트로-삭제&#41;)

[comment]: <> (  - [쉘 스크립트로 폐쇄망 구축]&#40;#쉘-스크립트로-폐쇄망-구축&#41;)

[comment]: <> (## 설치 yaml 파일 )

[comment]: <> (- 설치에 필요한 yaml 파일들은 deployments 폴더에 있습니다.)

[comment]: <> (## Step 1. CRD 생성 )

[comment]: <> (* 목적 : console-operator 동작에 필요한 console CRD를 생성한다. )

[comment]: <> (* 순서: )

[comment]: <> (    1. deployments 폴더에 [1.crd.yaml]&#40;https://raw.githubusercontent.com/tmax-cloud/install-console/5.0/deployments/1.crd.yaml&#41; 파일을 생성한다. )

[comment]: <> (    2. `kubectl apply -f 1.crd.yaml` 실행합니다. )

[comment]: <> (## Step 2. Namespace, ServiceAccount, ClusterRole, ClusterRoleBinding 생성)

[comment]: <> (* 목적 : console에 필요한 Namespace, ResourceQuota, ServiceAccount, ClusterRole, ClusterRoleBinding을 생성한다.)

[comment]: <> (* 순서 : )

[comment]: <> (    1. deployments 폴더에 [2.init.yaml]&#40;https://raw.githubusercontent.com/tmax-cloud/install-console/5.0/deployments/2.init.yaml&#41; 파일을 생성한다. )

[comment]: <> (	    * 기본 namespace는 console-system으로 설정됩니다. )

[comment]: <> (    2. `kubectl apply -f 2.init.yaml` 을 실행합니다.)

[comment]: <> (## Step 3. Job으로 Secret &#40;TLS&#41; 생성)

[comment]: <> (* 목적 : console 웹서버가 https를 지원하게 한다.)

[comment]: <> (    * Job으로 self signing 인증서를 만들어 console-https-secret 이란 이름으로 secret에 저장한다. )

[comment]: <> (    * &#40;옵션&#41; self signing 인증서이므로 별도의 ca 인증서로 인증을 받기 위해서 [kubernetes.io]&#40;https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/&#41;를 참고해서 생성한다. )

[comment]: <> (* 순서 : )

[comment]: <> (    1. deployments 폴더 안의 [3.job.yaml]&#40;https://raw.githubusercontent.com/tmax-cloud/install-console/5.0/deployments/3.job.yaml&#41; 파일을 실행한다. )

[comment]: <> (	   * `kubectl apply -f 3.job.yaml`)

[comment]: <> (* 비고 : )

[comment]: <> (    * 폐쇄망에서 설치하는 경우 )

[comment]: <> (	    * image로 `jettech/kube-webhook-certgen:v1.3.0` 대신, `&#40;레포지토리 주소&#41;/jettech/kube-webhook-certgen:v1.3.0` 을 사용합니다.	  )

[comment]: <> (## Step 4. Service &#40;Load Balancer&#41; 생성)

[comment]: <> (* 목적 : 브라우저를 통해 console에 접속할 수 있게 한다.)

[comment]: <> (* 순서 : )

[comment]: <> (    1. deployments 폴더에 [4.svc-lb.yaml]&#40;https://raw.githubusercontent.com/tmax-cloud/install-console/5.0/deployments/4.svc-lb.yaml&#41; 파일을 실행한다. &#40;기본 서비스 이름은 console.console-system.svc로 만들어진다.&#41;)

[comment]: <> (    * `kubectl apply -f 4.svc-lb.yaml` 을 실행합니다.)

[comment]: <> (## Step 5. Deployment &#40;with Pod Template&#41; 생성)

[comment]: <> (* 목적 : console 웹서버를 호스팅할 pod를 생성한다.)

[comment]: <> (* 순서 : )

[comment]: <> (    1. deployments 폴더에 [5.deploy.yaml]&#40;https://github.com/tmax-cloud/install-console/blob/5.0/deployments/5.deploy.yaml&#41; 파일에 다음의 문자열들을 교체해줍니다.)
    
[comment]: <> (    | 문자열             | 상세내용                                                                                                                                                      | 형식예시         |)

[comment]: <> (    | ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------- |)

[comment]: <> (    | `@@OPERATOR_VER@@` | hypercloud-console 이미지 태그 입력                                                                                                                           | `5.1.x.x`        |)

[comment]: <> (    | `@@REALM@@`        | hyperauth이용하여 로그인 시 필요한 정보 입력                                                                                                                  | `tmax`           |)

[comment]: <> (    | `@@KEYCLOAK@@`     | `kubectl get svc -n hyperauth hyperauth` 에서 EXTERNAL-IP 확인하여 입력                                                                                       | `10.x.x.x`       |)

[comment]: <> (    | `@@CLIENTID@@`     | hyperauth이용하여 로그인 시 필요한 client 정보 입력                                                                                                           | `hypercloud5`    |)

[comment]: <> (    | `@@MC_MODE@@`      | Multi Cluster 모드로 설치하려는 경우 `true` 입력 &#40;Single Cluster모드일 경우 false&#41;                                                                                          | `true`           |)

[comment]: <> (    | `@@KIALI@@`        | `kubectl get ingress kiali -n istio-system -o=jsonpath="{.status.loadBalancer.ingress[0].ip}"` 에서 ADDRESS 확인하여 입력 &#40;https 기본 포트사용함, 별도입력 X&#41; | `10.x.x.x`       |)

[comment]: <> (    | `@@KIBANA@@`       | `kubectl get svc -n kube-logging kibana` 에서 CLUSTER-IP와 PORT&#40;defalut 5601&#41; 확인하여 입력 &#40;포트는 `:` 왼쪽 값 사용&#41;                                         | `10.x.x.x:5601`  |)

[comment]: <> (    | `@@KUBEFLOW@@`     | `kubectl svc -n istio-system istio-ingressgateway`에서 CLUSTER-IP 확인하여 입력 &#40;http 기본 포트 사용&#41;                                                         | `10.x.x.x`       |)

[comment]: <> (    | `@@GITLAB@@`       | 비고 참고                                                                                                                                                     | `http://gitlab/` |)

[comment]: <> (    | `@@CONSOLE_VER@@`  | hypercloud-console 이미지 태그 입력                                                                                                                           | `5.0.x.x`        |)
    
[comment]: <> (    * `kubectl apply -f 5.deploy.yaml` 을 실행합니다.)

[comment]: <> (* 비고)

[comment]: <> (    * 폐쇄망에서 설치하는 경우)

[comment]: <> (	    * image로 `tmaxcloudck/hypercloud-console:5.0.12.0` 대신, `&#40;레포지토리 주소&#41;/tmaxcloudck/hypercloud-console:5.0.12.0` 을 사용합니다.)

[comment]: <> (    * Single Cluster 모드로 설치하는 경우)

[comment]: <> (	    * 5.deploy.yaml 파일에서 --mc-mode=false &#40;default&#41;로 설정한다. )

[comment]: <> (    * Multicluster Console을 설치하는 경우)

[comment]: <> (	    * 5.deploy.yaml 파일에서 --mc-mode=true 로 설정한다. )

[comment]: <> (   *  GITLAB 주소 조회 )

[comment]: <> (      *  ``` kubectl -n gitlab-system exec -t $&#40;kubectl -n gitlab-system get pod | grep gitlab | awk '{print $1}'&#41; -- cat /tmp/shared/omnibus.env 2>/dev/null | grep -oP "external_url '\K[^']*&#40;?='&#41;" ```)


[comment]: <> (## Step 6. 동작 확인)

[comment]: <> (* 목적 : console이 정상적으로 동작하는지 확인한다.)

[comment]: <> (* 순서 : )

[comment]: <> (    1. `kubectl get po -n console-system` 을 실행하여 pod가 running 상태인지 확인합니다.)

[comment]: <> (    2. `kubectl get svc -n console-system` 을 실행하여 EXTERNAL-IP를 확인합니다.)

[comment]: <> (    3. `https://EXTERNAL-IP` 로 접속하여 동작을 확인합니다.)

[comment]: <> (## 삭제 가이드)

[comment]: <> (* 목적: `console을 삭제한다.`)

[comment]: <> (* 순서: 아래 kubectl 명령어로 console 구성 요소를 삭제한다. )

[comment]: <> (    * `kubectl delete ns console-system`)

[comment]: <> (## 쉘 스크립트로 설치)

[comment]: <> (* 목적: `installer.sh를 이용하여 console을 설치한다.`)

[comment]: <> (* 순서: )

[comment]: <> (    1. manifest 폴더 안의 console.config정보를 설정한다. )

[comment]: <> (    2. 쉘 스크립트의 실행권한을 부여한 후 실행한다. )

[comment]: <> (        ```sh)

[comment]: <> (        chmod +x installer.sh)

[comment]: <> (        ./installer.sh install)

[comment]: <> (        ```)

[comment]: <> (## 쉘 스크립트로 삭제 )

[comment]: <> (* 목적: `installer.sh를 이용하여 console을 삭제한다.`)

[comment]: <> (* 순서:)

[comment]: <> (    1. manifest 폴더로 이동한다. )

[comment]: <> (    2. installer.sh 이용하여 console 구성요소를 삭제한다. )

[comment]: <> (        ```sh)

[comment]: <> (        ./installer.sh uninstall)

[comment]: <> (        ```)

[comment]: <> (## 쉘 스크립트로 폐쇄망 구축 )

[comment]: <> (* 목적: `installer.sh를 이용하여 폐쇄망에 console을 설치한다.`)

[comment]: <> (* 순서:)

[comment]: <> (    1. manifest 폴더로 이동한 후 installer.sh 이용하여 필요한 이미지를 준비한다. )

[comment]: <> (        ```sh )

[comment]: <> (        cd install-console/manifest)

[comment]: <> (        ./installer.sh prepare-online)

[comment]: <> (    2. 폐쇄망 환경으로 전송한다. )

[comment]: <> (        ```sh )

[comment]: <> (         #생성된 파일 모두 scp명령어 또는 물리 매체를 통해 폐쇄망 환경으로 복사 )

[comment]: <> (        cd ../..)

[comment]: <> (        scp -r install-console <REMOTE_SERVER>:<PATH>)

[comment]: <> (        ```)

[comment]: <> (    3. manifest 폴더로 이동한 후 console.config 파일에 REGISTRY 항목에 폐쇄망 주소를 입력한다.  )

[comment]: <> (    4. installer.sh를 이용하여 폐쇄망 환경의 registry에 이미지를 push한다. )

[comment]: <> (        ``` sh )

[comment]: <> (        ./installer.sh prepare-offline)

[comment]: <> (        ```)
