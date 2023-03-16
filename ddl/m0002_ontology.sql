CREATE TABLE ontology (
  ontid int  PRIMARY KEY,
  name  text
);

CREATE TABLE concept (
  cid            serial   PRIMARY KEY,
  ontid          int      REFERENCES ontology,
  ont_code       text,
  label          text
  -- TODO (dmitri)
  -- label_tsvector tsvector GENERATED ALWAYS AS (to_tsvector('english', label)) STORED
);

CREATE UNIQUE INDEX concept_i1 ON concept (ontid, ont_code);
CREATE INDEX concept_i2 ON concept (lower(label), ontid, cid);

CREATE TABLE concept_synonym (
  cid              int NOT NULL REFERENCES concept,
  synonym          text
  -- TODO (dmitri)
  -- synonym_tsvector tsvector GENERATED ALWAYS AS (to_tsvector('english', synonym)) STORED
);

CREATE INDEX concept_synonym_i1 ON concept_synonym (cid);

CREATE TABLE concept_hierarchy (
  cid        int REFERENCES concept,
  parent_cid int REFERENCES concept
);

-- alternative: store the full parent-path(s) for each cid using the ltree data type, see e.g.
-- https://hoverbear.org/blog/postgresql-hierarchical-structures/
CREATE UNIQUE INDEX concept_hierarchy_i1 ON concept_hierarchy (cid, parent_cid);
CREATE UNIQUE INDEX concept_hierarchy_i2 ON concept_hierarchy (parent_cid, cid);
