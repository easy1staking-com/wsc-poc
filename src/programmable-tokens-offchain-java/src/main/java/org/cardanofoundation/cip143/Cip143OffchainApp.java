package org.cardanofoundation.cip143;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication(scanBasePackages = "org.cardanofoundation.cip143")
public class Cip143OffchainApp {

    public static void main(String[] args) {
        SpringApplication.run(Cip143OffchainApp.class, args);
    }

}
