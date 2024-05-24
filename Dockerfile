# 1. Gradle 이미지로 시작
FROM gradle:7.5-jdk17 as builder

# 2. 작업 디렉토리 설정
WORKDIR /app

# 3. Gradle 설정 파일과 의존성 파일 복사
COPY build.gradle settings.gradle ./
COPY gradle ./gradle

# 4. 의존성 다운로드 (캐싱 목적)
RUN gradle dependencies  --info

# 5. 프로젝트 소스 코드 복사
COPY . .

# 6. 프로젝트 빌드
RUN gradle build --info

# 7. 경량화된 JDK 이미지로 전환
FROM openjdk:17-jdk-slim

# 8. 작업 디렉토리 설정
WORKDIR /app

# 9. 빌드된 JAR 파일을 복사
COPY --from=builder /app/build/libs/zero-downtime-deployment-test-0.0.1-SNAPSHOT.jar app.jar

# 10. 애플리케이션 실행
ENTRYPOINT ["java", "-jar", "app.jar"]
