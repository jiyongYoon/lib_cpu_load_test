#!/bin/bash
# 1. 기존 배포된 Type의 반대 버전 docker-compose 실행하기
# 2. 새로 배포된 Type을 activate_metadata_file에 수정하기
# 3. nginx conf 새로 배포된 Type으로 load-balancing 하기
# 4. 기존 배포된 Type의 docker-compose 내리기 (rollback-master.sh에서 실행되면 내리지 않음)

# 변수 세팅
ACTIVATE_METADATA_FILENAME="./activate_deploy_version"
NGINX_CONFIG="./proxy/nginx.conf"
NGINX_SERVICE_NAME="nginx"

DEFAULT_DOCKER_COMPOSE_BLUE="docker-compose-blue.yml"
DEFAULT_DOCKER_COMPOSE_GREEN="docker-compose-green.yml"
NGINX_DOCKER_COMPOSE_NAME="docker-compose-nginx.yml"

BLUE_SERVER_URL="\$blue_server_url"
GREEN_SERVER_URL="\$green_server_url"

# RUN_TYPE을 가져오는 함수
get_current_run_type() {
  if [ -f "$ACTIVATE_METADATA_FILENAME" ]; then
    RUN_TYPE=$(grep -oP '(?<=RUN_TYPE=")[^"]+' $ACTIVATE_METADATA_FILENAME)
  fi
  echo ${RUN_TYPE:-blue} # RUN_TYPE이 없으면 기본값으로 blue 반환
}

# DOCKER_COMPOSE_UP_FILENAME 설정 -> 기존 RUN_TYPE과 반대되는 compose 파일 실행
RUN_TYPE=$(get_current_run_type)
echo "-- 기존 배포된 RUN_TYPE: $RUN_TYPE --"

if [ "$RUN_TYPE" = "blue" ]; then
  DOCKER_COMPOSE_UP_FILENAME=$DEFAULT_DOCKER_COMPOSE_GREEN
  DOCKER_COMPOSE_DOWN_FILENAME=$DEFAULT_DOCKER_COMPOSE_BLUE
  UP_SERVER_URL=$GREEN_SERVER_URL
  DOWN_SERVER_URL=$BLUE_SERVER_URL
elif [ "$RUN_TYPE" = "green" ]; then
  DOCKER_COMPOSE_UP_FILENAME=$DEFAULT_DOCKER_COMPOSE_BLUE
  DOCKER_COMPOSE_DOWN_FILENAME=$DEFAULT_DOCKER_COMPOSE_GREEN
  UP_SERVER_URL=$BLUE_SERVER_URL
  DOWN_SERVER_URL=$GREEN_SERVER_URL
else
  DOCKER_COMPOSE_UP_FILENAME=$DEFAULT_DOCKER_COMPOSE_BLUE
  DOCKER_COMPOSE_DOWN_FILENAME=$DEFAULT_DOCKER_COMPOSE_GREEN
fi

# build & Up
#docker-compose -f ./docker/$DOCKER_COMPOSE_UP_FILENAME up --build -d # 코드가 바뀌는 버전업 배포라면 매번 새롭게 빌드
docker-compose -f ./docker/$DOCKER_COMPOSE_UP_FILENAME up -d

# docker compose up이 성공적으로 실행된 경우
if [ $? -eq 0 ]; then
  # 현재 사용된 RUN_TYPE에 따라 ACTIVATE_METADATA_FILENAME 파일 수정
  if [ "$RUN_TYPE" = "blue" ]; then
    NEW_RUN_TYPE="green"
  else
    NEW_RUN_TYPE="blue"
  fi

  # ACTIVATE_METADATA_FILENAME 업데이트
  sed -i "s/^RUN_TYPE=.*/RUN_TYPE=\"$NEW_RUN_TYPE\"/" $ACTIVATE_METADATA_FILENAME
  sed -i "s/^ROLLBACK_TYPE=.*/ROLLBACK_TYPE=\"$RUN_TYPE\"/" $ACTIVATE_METADATA_FILENAME

  echo "-- 새로 배포된 RUN_TYPE: $NEW_RUN_TYPE, activate_deploy_version 파일 업데이트 완료. --"
fi

########## nginx reload ##########

# 기본값 설정
NGINX_OPTION=true

# 옵션 파싱
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --nginx=false)
            NGINX_OPTION=false
            shift # 다음 인수로 이동
            ;;
        --nginx)
            NGINX_OPTION=true
            shift # 다음 인수로 이동
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done


# 옵션에 따른 분기 처리
if [ "$NGINX_OPTION" = true ]; then
    sed -i "s#proxy_pass http://$DOWN_SERVER_URL:8080;#proxy_pass http://$UP_SERVER_URL:8080;#g" $NGINX_CONFIG
    docker-compose -f ./docker/$NGINX_DOCKER_COMPOSE_NAME exec $NGINX_SERVICE_NAME nginx -s reload
    echo "Nginx reload finished!!"
fi

######### 기존 docker-compose down ##########

# 기본값 설정
PREVIOUS_COMPOSE_DOWN=true

# 옵션 파싱
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --previous=false)
            PREVIOUS_COMPOSE_DOWN=false
            shift # 다음 인수로 이동
            ;;
        --previous)
            PREVIOUS_COMPOSE_DOWN=true
            shift # 다음 인수로 이동
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ "$PREVIOUS_COMPOSE_DOWN" = true ]; then
  docker-compose -f ./docker/$DOCKER_COMPOSE_DOWN_FILENAME down
  echo "-- 기존 배포된 docker-compose DOWN: $DOCKER_COMPOSE_DOWN_FILENAME"
fi