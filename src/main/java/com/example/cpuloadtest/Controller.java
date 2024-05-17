package com.example.cpuloadtest;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

@RestController
@RequestMapping("/cpu")
public class Controller {

    @GetMapping("/{count}")
    public void cpuLoadTest(@PathVariable Integer count) throws InterruptedException {
        // 실행 횟수 설정
        int executionCount = count == null ? 100 : count; // 원하는 실행 횟수로 변경

        // ExecutorService 생성 (스레드 풀 사용)
        ExecutorService executorService = Executors.newFixedThreadPool(10); // 동시 실행 스레드 수 설정

        // 지정된 횟수만큼 CPU 부하 작업 실행
        for (int i = 0; i < executionCount; i++) {
            executorService.submit(() -> {
                for (int j = 0; j < 1000000; j++) {
                    double random = Math.random();
                }
            }); // CPU 부하 작업 스레드 풀에 제출
        }

        // 모든 작업 완료까지 기다림
        executorService.shutdown();
        executorService.awaitTermination(Long.MAX_VALUE, TimeUnit.MILLISECONDS);

        System.out.println("CPU 부하 작업 완료!");
    }
}
