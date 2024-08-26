# blue-green 무중단 배포 연습

Kubernetes 를 도입하기 전에 무중단 배포를 스크립트로 할 수 있는 방법에 대한 학습 

---

## 1. blue-green 무중단 배포 - V1

- proxy 외에 서버 포트들도 외부에 노출하는 경우에만 사용 가능

### Working Directory
`./zero-downtime-deployment-v1`

### 실행방법 
1. `docker-compose -f ./docker/docker-compose-nginx.yml up -d`
2. `./deploy.sh` -> 계속 실행하여 무중단 배포 번갈아가며 확인 가능
    - 확인 api: `/localhost/health`

### 동작 순서
1. `./proxy/nginx.conf` 파일이 docker-compose 볼륨으로 잡혀 config가 적용됨
2. `./deploy.sh`을 실행하면 `빌드 및 도커 업` -> `Nginx 설정 수정 및 Restart` -> `기존 도커 삭제` 순서로 진행

### 특징
- ~~무중단 배포가 가능하나, 배포 시 spring-profile의 port가 변경되어 배포됨.~~
- 개선 작업 중, port 변경 없이 가능함을 확인함
  - docker-compose의 `ports`의 `외부 port`만 변경되고 바인딩 되는 `내부 port`는 profile에서 동일하게 사용해도 무방함을 확인! (왜 이생각을 못했을까....)
    - green
      ```yaml
      ports:
        - 8080:8080
      ```
    - blue
      ```yaml
      ports:
        - 8081:8080
      ```
    - nginx.conf
      ```nginx configuration
      # green
      location / {
        proxy_pass http://host.docker.internal:8080;
      }
      
      # blue
      location / {
        proxy_pass http://host.docker.internal:8081;
      }
      ```
  - 대신, 외부의 접근을 막기 위해 `expose`로 `내부 port`만을 여는 경우는 해당 작업이 불가능.
- port의 외부 노출 없이 `expose`를 사용하며, docker-network를 활용하여 무중단 배포를 하도록 개선 => `V2`

---

## 2. blue-green 무중단 배포 - V2

- 서버 포트는 expose로 내부에서만 접근 가능하도록 하여 사용 가능

### Working Directory
`./zero-downtime-deployment-v2

### 실행방법
1. `./docker/docker_network_generate.sh` 실행하여 green - blue network를 생성
2. `docker-compose -f ./docker/docker-compose-nginx.yml up -d`
3. `./deploy.sh` -> 계속 실행하여 무중단 배포 번갈아가며 확인 가능
   - 확인 api: `/localhost/health`

### 동작 순서
1. `./proxy/nginx.conf` 파일이 docker-compose 볼륨으로 잡혀 config가 적용됨
2. `./deploy.sh`을 실행하면 `빌드 및 도커 업` -> `Nginx 설정 수정 및 Restart` -> (컨테이너가 잘 실행되면) `activate_deploy_version 파일 수정` -> `기존 도커 삭제` 순서로 진행

### 특징
- 서버 컨테이너의 포트를 노출시키지 않을 수 있어 보안에 안전함. 컨테이너간 통신은 `docker-network`를 활용함
   - 로드벨런싱 및 프록시 역할을 하는 nginx는 양쪽 네트워크를 모두 물고 있음
- `./activate_deploy_version`을 통해 현재 실행중인 버전을 확인하고 외부에서도 해당 파일을 활용할 수 있도록 수정
- 이후에는 version env 파일을 만들어 버전을 자동으로 up - down하게 하도록 개선이 가능함.