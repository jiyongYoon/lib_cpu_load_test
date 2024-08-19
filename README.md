# 1. blue-green 무중단 배포 - V1

## Working Directory
`./zero-downtime-deployment-v1`

## 실행방법 
1. `docker-compose -f ./docker/docker-compose-nginx.yml up -d`
2. `./deploy.sh` -> 계속 실행하여 무중단 배포 번갈아가며 확인 가능
    - 확인 api: `/localhost/health`

## 동작 순서
1. `./proxy/nginx.conf` 파일이 docker-compose 볼륨으로 잡혀 config가 적용됨
2. `./deploy.sh`을 실행하면 `빌드 및 도커 업` -> `Nginx 설정 수정 및 Restart` -> `기존 도커 삭제` 순서로 진행

## 특징
- 무중단 배포가 가능하나, 배포 시 port가 변경되어 배포됨.
- port 변경 없이 docker-network를 활용하여 무중단 배포를 하도록 개선 가능
