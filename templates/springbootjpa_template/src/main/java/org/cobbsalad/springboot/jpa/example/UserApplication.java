package org.cobbsalad.springboot.jpa.example;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import java.util.stream.LongStream;

@SpringBootApplication
public class UserApplication {

    public static void main(String[] args) {
        SpringApplication.run(UserApplication.class, args);
    }

    CommandLineRunner init(UserRepository repository) {
        return args -> {
            repository.deleteAll();
            LongStream.range(1,11)
                    .mapToObj(i -> {
                        User e = new User();
                        e.setName("User " + i);
                        e.setEmail("user" + i + "@gmail.com");
                        e.setPhone(("010-0000-0000"));
                        return e;
                    })
                    .map(v -> repository.save(v))
                    .forEach(System.out::println);
        };
    }
}
