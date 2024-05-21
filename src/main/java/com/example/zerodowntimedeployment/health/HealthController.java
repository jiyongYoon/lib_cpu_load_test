package com.example.zerodowntimedeployment.health;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/health")
public class HealthController {

    @GetMapping
    public String v1HealthCheck() {
        String message = "hello, this is v1!";
        System.out.println(message);
        return message;
    }

}
