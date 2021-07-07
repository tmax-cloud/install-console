# Installer 사용 방법

## 전체 설치
* 작업 디렉토리 및 환경 설정 
   '''sh
      git clone https://github.com/tmax-cloud/install-console.git -b 5.0 --single-branch 
      cd install-console/manifest 
   '''
### 공통
1. console.config 설정
   - REGISTRY: 레지스트리 주소 입력 (폐쇄망이 아닐 경우 빈 값으로 설정)
   - CONSOLE_VER: 콘솔 이미지 버전 
   - OPERATOR_VER: 콘솔 오퍼레이터 이미지 버전 
   - REALM: hyperauth의 REALM 정보 
   - KEYCLOAK: hyperauth의 ip주소 혹은 도메인 주소
   - CLIENTID: hpperauth의 Client id 정보 
   - MC_MODE: 멀티클러스터/싱글클러스터 모드 설정 (true일 경우 멀티클러스터)
   - RELEASE_MODE: 배포일 경우 true, 개발용인 경우 false
   - KIALI: 키알리 서버 주소 
   - KIBANA: 키바나 서버 주소 
   - KUBEFLOW: 쿠베플로우 서버 주소 
   - GITLAB: 깃랩 주소 

### 폐쇄망일 경우
1. 온라인 환경에서 준비
   ```bash
   ./installer.sh prepare-online
   ```
2. 해당 폴더 (`./yaml`, `./tar` 포함) 폐쇄망 환경으로 복사
3. 실제 폐쇄망 환경에서 준비
   ```bash
   ./installer.sh prepare-offline
   ```
### 공통
```bash
./installer.sh install
```

## 전체 삭제
```bash
./installer.sh uninstall
```