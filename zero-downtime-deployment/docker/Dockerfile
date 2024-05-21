# 1. Gradle 이미지로 시작
FROM gradle:7.5-jdk17 as builder

# 1-1. 변수 정의
ARG SRC_DIR=src/
ARG PROJECT_DIR=zero-downtime-deployment
ARG APP_HOME=/app

# 2. 작업 디렉토리 설정
WORKDIR $APP_HOME

# 3. Gradle 설정 파일과 의존성 파일 복사
COPY $PROJECT_DIR/docker/gradle/build.gradle $PROJECT_DIR/docker/gradle/settings.gradle ./
COPY $PROJECT_DIR/docker/gradle/gradle ./gradle

# 4. 의존성 다운로드 (캐싱 목적)
RUN gradle dependencies  --info

# 5. 프로젝트 소스 코드 복사
COPY $PROJECT_DIR/ ./
COPY $SRC_DIR ./src

# 6. 프로젝트 빌드
RUN gradle build --info

# 7. 경량화된 JDK 이미지로 전환
FROM openjdk:17-jdk-slim

# 8. 작업 디렉토리 설정
ARG APP_HOME=/app
WORKDIR $APP_HOME

# 9. 빌드된 JAR 파일을 복사
COPY --from=builder $APP_HOME/build/libs/cpu-load-test-0.0.1-SNAPSHOT.jar app.jar

# 10. 애플리케이션 실행
ENTRYPOINT ["java", "-jar", "app.jar"]
