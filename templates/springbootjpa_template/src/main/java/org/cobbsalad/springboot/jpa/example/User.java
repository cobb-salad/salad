package org.cobbsalad.springboot.jpa.example;

import lombok.Data;

import javax.annotation.sql.DataSourceDefinition;
import javax.persistence.*;

@Data
@Entity
@Table(name="employee")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;
    private String email;
    private String phone;
}
