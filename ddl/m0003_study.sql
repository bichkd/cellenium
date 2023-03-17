-- TODO import tracking belongs in its own table (dmitri)
CREATE TABLE study (
  study_id           int4 PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  name               text NOT NULL,
  filename           text,
  description        text,
  external_website   text,
  tissue_ncit_ids    text[],
  disease_mesh_ids   text[],
  cell_ontology_ids  text[],
  organism_tax_id    text,
  cell_count         int4,
  projections        text[],
  visible            bool DEFAULT false,
  import_started     bool DEFAULT false,
  import_failed      bool DEFAULT false,
  import_log         text,
  reader_permissions text[],
  admin_permissions  text[],
  legacy_config      jsonb
);

-- TODO annotations in general (dmitri)
-- e.g. an annotation category, like 'cell ontology name'
CREATE TABLE annotation_group (
  annotation_group_id int4 PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  h5ad_column         text NOT NULL UNIQUE,
  display_group       text NOT NULL
);

-- e.g. an annotation category value, like 'lymphocyte'
CREATE TABLE annotation_value (
  annotation_value_id int4 PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  annotation_group_id int4 NOT NULL REFERENCES annotation_group,
  h5ad_value          text NOT NULL,
  display_value       text NOT NULL,
  UNIQUE (annotation_group_id, h5ad_value)
);

CREATE INDEX ON annotation_value (annotation_group_id) INCLUDE (annotation_value_id);
CREATE INDEX ON annotation_value (annotation_value_id) INCLUDE (display_value, annotation_group_id);

CREATE TABLE study_annotation_group_ui (
  study_id                           int4 NOT NULL REFERENCES study ON DELETE CASCADE,
  annotation_group_id                int4 NOT NULL REFERENCES annotation_group,
  is_primary                         bool NOT NULL,
  ordering                           int4 NOT NULL,
  differential_expression_calculated bool NOT NULL
);

-- TODO how is 'study_sample_id' assigned? (dmitri)
CREATE TABLE sample (
  sample_id       int4 NOT NULL,
  study_id        int4 NOT NULL REFERENCES study ON DELETE CASCADE,
  h5ad_obs_index  int4 NOT NULL,
  h5ad_obs_key    text NOT NULL,
  PRIMARY KEY (study_id, sample_id) -- TODO not a fan of compound primary keys (dmitri)
);

-- TODO needs a primary key
-- ... or is this a value table?
CREATE TABLE projection (
  study_id            int4   NOT NULL,
  sample_id           int4   NOT NULL,
  projection_type     text   NOT NULL,
  modality            text,
  projection          real[] NOT NULL, -- TODO non-null containers not usually meaningful (dmitri)
  -- subsampling reduces overlapping points in a projection
  display_subsampling bool   NOT NULL,
  FOREIGN KEY (study_id, sample_id) REFERENCES sample (study_id, sample_id) ON DELETE CASCADE
);


-- TODO likely not a great use of array (dmitri)
CREATE TABLE sample_annotation (
  study_id            int4   NOT NULL REFERENCES study ON DELETE CASCADE,
  annotation_value_id int4   NOT NULL REFERENCES annotation_value,
  -- the samples that are annotated with that value, e.g. that specific cell type
  sample_ids          int4[] NOT NULL,
  color               text,
  UNIQUE (study_id, annotation_value_id)
);

