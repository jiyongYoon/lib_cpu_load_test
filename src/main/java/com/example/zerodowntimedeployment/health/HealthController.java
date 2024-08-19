package com.example.zerodowntimedeployment.health;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/health")
public class HealthController {

    @Value("${hello.message}")
    private String helloMessage;

    @GetMapping
    public String v1HealthCheck() {
        System.out.println(helloMessage);
        return helloMessage;
    }

}
