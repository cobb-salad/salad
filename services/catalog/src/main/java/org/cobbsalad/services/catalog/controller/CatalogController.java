package org.cobbsalad.services.catalog.controller;

import org.cobbsalad.services.catalog.dao.CatalogRepository;
import org.cobbsalad.services.catalog.model.Catalog;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping({"/catalog"})
public class CatalogController {

    private CatalogRepository repository;

    CatalogController(CatalogRepository catalogRepository){
        this.repository = catalogRepository;
    }

    @GetMapping
    public List findAll(){
        return repository.findAll();
    }

    @GetMapping(path={"/{id}"})
    public ResponseEntity<Catalog> findById(@PathVariable long id) {
        return repository.findById(id)
                .map(record -> ResponseEntity.ok().body(record))
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public Catalog create(@RequestBody Catalog catalog) {
        return repository.save(catalog);
    }

    @PutMapping(value="/{id}")
    public ResponseEntity<Catalog> update(@PathVariable("id") long id, @RequestBody Catalog catalog) {
        return repository.findById(id)
                .map(record -> {
                    record.setName(catalog.getName());
                    record.setCreator(catalog.getCreator());
                    record.setCreatedAt(catalog.getCreatedAt());
                    record.setModifiedAt(catalog.getModifiedAt());
                    Catalog updated = repository.save(record);
                    return ResponseEntity.ok().body(updated);
                }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping(path = {"/{id}"})
    public ResponseEntity<?> delete(@PathVariable("id") long id) {
        return repository.findById(id)
                .map(record -> {
                    repository.deleteById(id);
                    return ResponseEntity.ok().build();
                }).orElse(ResponseEntity.notFound().build());
    }
}
