#!/bin/bash
HOST="http://host.docker.internal"
#HOST="127.0.0.1"
NGINX_CONFIG="./proxy/nginx.conf"
NGINX_SERVICE_NAME="nginx"
BLUE_PORT="8081"
GREEN_PORT="8080"
BLUE_DOCKER_COMPOSE_NAME="docker-compose-blue.yml"
GREEN_DOCKER_COMPOSE_NAME="docker-compose-green.yml"
NGINX_DOCKER_COMPOSE_NAME="docker-compose-nginx.yml"

CURRENT_PORT=$(grep "proxy_pass $HOST:" "$NGINX_CONFIG" | awk '{print $2}' | cut -d ':' -f 3 | sed 's/;//' | tr -d '[:space:]')
echo -e "Old = $CURRENT_PORT\n"
# 포트 변경
if [ "$CURRENT_PORT" = "$BLUE_PORT" ]; then
    NEW_PORT=$GREEN_PORT
    NEW_DOCKER_COMPOSE_NAME=$GREEN_DOCKER_COMPOSE_NAME
    OLD_DOCKER_COMPOSE_NAME=$BLUE_DOCKER_COMPOSE_NAME
elif [ "$CURRENT_PORT" = "$GREEN_PORT" ]; then
    NEW_PORT=$BLUE_PORT
    NEW_DOCKER_COMPOSE_NAME=$BLUE_DOCKER_COMPOSE_NAME
    OLD_DOCKER_COMPOSE_NAME=$GREEN_DOCKER_COMPOSE_NAME
else
    echo '서버의 blue green 포트 확인 실패\n';
    exit 1;
fi

echo -e "New $NEW_PORT\n"

# docker pull & run
echo -e "## new docker build & run ##\n"
docker-compose -f ./docker/$NEW_DOCKER_COMPOSE_NAME up --build -d

# NGINX 설정 파일 수정
echo -e "## Nginx 설정 수정 & restart ##\n"
sed -i "s#proxy_pass $HOST:$CURRENT_PORT;#proxy_pass $HOST:$NEW_PORT;#g" $NGINX_CONFIG
docker-compose -f ./docker/$NGINX_DOCKER_COMPOSE_NAME exec $NGINX_SERVICE_NAME nginx -s reload

# 기존 docker container 제거
echo -e "## old docker 제거 ##\n"
docker-compose -f ./docker/$OLD_DOCKER_COMPOSE_NAME down

# summary
echo -e "## down port: $CURRENT_PORT, down compose: $OLD_DOCKER_COMPOSE_NAME"
echo -e "## up port: $NEW_PORT, up compose: $NEW_DOCKER_COMPOSE_NAME"