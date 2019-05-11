package org.cobbsalad.services.catalog.model;

import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;

import javax.persistence.*;
import java.util.Date;

@Data
@Entity
@Table(name="catalog")
public class Catalog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String  name;
    private String  creator;

    @Column(name="created_at")
    @Temporal(TemporalType.TIMESTAMP)
//    @CreationTimestamp
    private Date    createdAt;

    @Column(name="modified_at")
    @Temporal(TemporalType.TIMESTAMP)
    private Date    modifiedAt;
}
