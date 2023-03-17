CREATE TABLE ontology (
  ontology_id int4 PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  name        text NOT NULL
);

-- TODO function of ont_code (dmitri)
-- TODO foreign key cascade behavior (dmitri)
CREATE TABLE concept (
  concept_id  int4 PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  ontology_id int4 NOT NULL REFERENCES ontology,
  ont_code    text,
  label       text,
  -- TODO (dmitri)
  -- label_tsvector tsvector GENERATED ALWAYS AS (to_tsvector('english', label)) STORED
  UNIQUE (ontology_id, ont_code) -- TODO unique on nullable
);
-- TODO 'concept_id' adds nothing to the index; and likely ontology_id, too (dmitri)
CREATE INDEX ON concept (lower(label), ontology_id, concept_id);

-- TODO not my favorite structure: either an array field on 'concept' or a proper synonym entity
CREATE TABLE concept_synonym (
  concept_id int4 NOT NULL REFERENCES concept,
  synonym    text NOT NULL
  -- TODO (dmitri)
  -- synonym_tsvector tsvector GENERATED ALWAYS AS (to_tsvector('english', synonym)) STORED
);
CREATE INDEX ON concept_synonym (concept_id);

-- alternative: store the full parent-path(s) for each cid using the ltree data type, see e.g.
-- https://hoverbear.org/blog/postgresql-hierarchical-structures/
CREATE TABLE concept_hierarchy (
  concept_id int4 REFERENCES concept,
  parent_id  int4 REFERENCES concept,
  UNIQUE (concept_id, parent_id)
);
CREATE INDEX ON concept_hierarchy (parent_id);
