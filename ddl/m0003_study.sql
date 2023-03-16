CREATE TABLE study (
  filename           text,
  study_id           serial PRIMARY KEY,
  study_name         text NOT NULL,
  description        text,
  external_website   text,
  tissue_ncit_ids    text[],
  disease_mesh_ids   text[],
  cell_ontology_ids  text[],
  organism_tax_id    text,
  cell_count         int,
  projections        text[],
  visible            boolean default False,
  import_started     boolean default False,
  import_failed      boolean default False,
  import_log         text,
  reader_permissions text[],
  admin_permissions  text[],
  legacy_config      jsonb
);


-- e.g. an annotation category, like 'cell ontology name'
CREATE TABLE annotation_group (
  annotation_group_id serial PRIMARY KEY,
  h5ad_column         text NOT NULL,
  display_group       text NOT NULL
);
CREATE UNIQUE INDEX annotation_group_1 ON annotation_group (h5ad_column);

-- e.g. an annotation category value, like 'lymphocyte'
CREATE TABLE annotation_value (
  annotation_value_id serial PRIMARY KEY,
  annotation_group_id int  NOT NULL REFERENCES annotation_group,
  h5ad_value          text NOT NULL,
  display_value       text NOT NULL
);

CREATE UNIQUE INDEX annotation_value_1 ON annotation_value (annotation_group_id, h5ad_value);
CREATE INDEX annotation_value_2 ON annotation_value (annotation_group_id) include (annotation_value_id);
CREATE INDEX annotation_value_3 ON annotation_value (annotation_value_id) include (display_value, annotation_group_id);

CREATE TABLE study_annotation_group_ui (
  study_id                           int     NOT NULL,
  annotation_group_id                int     NOT NULL REFERENCES annotation_group,
  is_primary                         boolean NOT NULL,
  ordering                           int     NOT NULL,
  differential_expression_calculated boolean NOT NULL,
  CONSTRAINT fk_study_id FOREIGN KEY (study_id) REFERENCES study (study_id) ON DELETE CASCADE
);

CREATE TABLE study_sample (
  study_id        int  NOT NULL,
  study_sample_id int  NOT NULL,
  h5ad_obs_index  int  NOT NULL,
  h5ad_obs_key    text NOT NULL,
  CONSTRAINT pk_study_sample PRIMARY KEY (study_id, study_sample_id),
  CONSTRAINT fk_study_id FOREIGN KEY (study_id) REFERENCES study (study_id) ON DELETE CASCADE
);

CREATE TABLE study_sample_projection (
  study_id            int     NOT NULL,
  study_sample_id     int     NOT NULL,
  projection_type     text    NOT NULL,
  modality            text,
  projection          real[]  NOT NULL,
  -- subsampling reduces overlapping points in a projection
  display_subsampling boolean NOT NULL,
  CONSTRAINT fk_study_sample FOREIGN KEY (study_id, study_sample_id) REFERENCES study_sample (study_id, study_sample_id) ON DELETE CASCADE
);


CREATE TABLE study_sample_annotation (
  study_id            int   NOT NULL,
  annotation_value_id int   NOT NULL,
  -- the samples that are annotated with that value, e.g. that specific cell type
  study_sample_ids    int[] NOT NULL,
  color               text,
  CONSTRAINT fk_study_id FOREIGN KEY (study_id) REFERENCES study (study_id) ON DELETE CASCADE,
  CONSTRAINT fk_sample_annotation_value FOREIGN KEY (annotation_value_id) REFERENCES annotation_value (annotation_value_id)
);
CREATE UNIQUE INDEX study_sample_annotation_1 ON study_sample_annotation (study_id, annotation_value_id);

