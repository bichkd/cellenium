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

-- TODO short-cicruit visibility for now (dmitri)
CREATE VIEW study_visible_currentuser AS SELECT s.study_id FROM study s;
CREATE VIEW study_administrable_currentuser AS SELECT s.study_id FROM study s;

CREATE TYPE omics_type AS ENUM ('gene', 'protein_antibody_tag', 'transcription_factor', 'region');

CREATE TABLE omics_base (
  omics_id       serial PRIMARY KEY,
  omics_type     omics_type NOT NULL,
  tax_id         int        NOT NULL,
  display_symbol text       NOT NULL,
  display_name   text
  );

CREATE TABLE omics_gene (
  gene_id         int  NOT NULL REFERENCES omics_base PRIMARY KEY,
  ensembl_gene_id text NOT NULL,
  entrez_gene_ids text[],
  hgnc_symbols    text[]
  );
CREATE UNIQUE INDEX omics_gene_1 ON omics_gene (ensembl_gene_id);

CREATE TABLE omics_region (
  region_id      int  NOT NULL REFERENCES omics_base PRIMARY KEY,
  chromosome     text NOT NULL,
  start_position int  NOT NULL,
  end_position   int  NOT NULL,
  region         text NOT NULL
);

CREATE UNIQUE INDEX omics_region_1 ON omics_region (region);

CREATE TABLE omics_region_gene (
  region_id int NOT NULL REFERENCES omics_region,
  gene_id   int NOT NULL REFERENCES omics_gene
);
CREATE UNIQUE INDEX omics_region_gene_1 ON omics_region_gene (region_id, gene_id);

-- TODO I had to add this to fix a postgraphile schema generation problem
-- COMMENT ON CONSTRAINT "omics_region_region_id_fkey" ON "public"."omics_region" IS E'@fieldName omics_region_newNameHere';

CREATE TABLE omics_protein_antibody_tag (
  protein_antibody_tag_id int  NOT NULL REFERENCES omics_base PRIMARY KEY,
  tax_id                  int  NOT NULL,
  antibody_symbol         text NOT NULL
);
CREATE UNIQUE INDEX omics_protein_antibody_tag_1 ON omics_protein_antibody_tag (tax_id, antibody_symbol);


CREATE TABLE omics_protein_antibody_tag_gene (
  protein_antibody_tag_id int NOT NULL REFERENCES omics_protein_antibody_tag,
  gene_id                 int NOT NULL REFERENCES omics_gene
);
CREATE UNIQUE INDEX omics_protein_antibody_tag_gene_1 ON omics_protein_antibody_tag_gene (protein_antibody_tag_id, gene_id);

CREATE TABLE omics_transcription_factor (
  omics_id         int  PRIMARY KEY REFERENCES omics_base,
  jaspar_matrix_id text NOT NULL
);
CREATE UNIQUE INDEX omics_transcription_factor_1 ON omics_transcription_factor (jaspar_matrix_id);


CREATE TABLE omics_transcription_factor_gene (
  transcription_factor_id int NOT NULL REFERENCES omics_transcription_factor,
  gene_id                 int NOT NULL REFERENCES omics_gene
);
CREATE UNIQUE INDEX omics_transcription_factor_gene_1 ON omics_transcription_factor_gene (transcription_factor_id, gene_id);

-- TODO (dmitri)
CREATE OR REPLACE VIEW omics_all AS
SELECT
b.omics_id,
b.omics_type,
b.tax_id,
b.display_symbol,
b.display_name,
og.ensembl_gene_id,
og.entrez_gene_ids,
og.hgnc_symbols,
ogr.region,
array_remove(array_agg(otfg.gene_id) || array_agg(opatg.gene_id) || array_agg(ogrg.gene_id), null) AS linked_genes
FROM omics_base b
LEFT JOIN omics_gene og ON b.omics_id = og.gene_id
LEFT JOIN omics_region ogr ON b.omics_id = ogr.region_id
LEFT JOIN omics_region_gene ogrg ON b.omics_id = ogrg.region_id
LEFT JOIN omics_protein_antibody_tag_gene opatg ON b.omics_id = opatg.protein_antibody_tag_id
LEFT JOIN omics_transcription_factor_gene otfg ON b.omics_id = otfg.transcription_factor_id
GROUP BY og.ensembl_gene_id, og.entrez_gene_ids, og.hgnc_symbols, b.omics_id, b.omics_type, b.tax_id, b.display_symbol, b.display_name, ogr.region
;

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

CREATE OR REPLACE VIEW study_sample_projection_subsampling_transposed AS
SELECT
study_id,
projection_type,
modality,
array_agg(study_sample_id ORDER BY study_sample_id) AS study_sample_id,
array_agg(projection ORDER BY study_sample_id) AS projection
FROM study_sample_projection
WHERE display_subsampling = true
GROUP BY study_id, projection_type, modality
;

-- TODO (dmitri)
-- comment ON view study_sample_projection_subsampling_transposed is
-- E'@foreignKey (study_id) REFERENCES study (study_id)|@fieldName study|@foreignFieldName studySampleProjectionSubsamplingTransposed';

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

-- contains all samples which appear in at least one projection
CREATE or replace VIEW study_sample_annotation_subsampling AS
SELECT
ssa.study_id,
ssa.annotation_value_id,
array_agg(distinct ssp.study_sample_id) study_sample_ids
FROM study_sample_annotation ssa
CROSS JOIN unnest(ssa.study_sample_ids) sample_id
JOIN study_sample_projection ssp ON ssp.study_id = ssa.study_id AND ssp.study_sample_id = sample_id
WHERE ssp.display_subsampling = True
GROUP BY ssa.study_id, ssa.annotation_value_id
;

-- TODO (dmitri)
-- comment ON view study_sample_annotation_subsampling is
-- E'@foreignKey (study_id) REFERENCES study (study_id)|@fieldName study|@foreignFieldName studySampleAnnotationSubsampling';

CREATE TABLE study_omics (
  study_id       int NOT NULL,
  omics_id       int NOT NULL REFERENCES omics_base,
  -- indexing the h5ad .uns['protein_X'] matrix in this study
  h5ad_var_index int NOT NULL,
  -- TODO add another h5ad_col_index for second h5ad file (ATAC-seq)? Or better use h5ad format to combine atac-seq into same h5ad file
  -- TODO: AS --> should actually be fine as rna and atac have different omics_id
  -- region as seen in the actual study data before 'fuzzy' region matching with bedtools (expect same build, chromosome)
  region_start   int,
  region_end     int,
  CONSTRAINT fk_study_id FOREIGN KEY (study_id) REFERENCES study (study_id) ON DELETE CASCADE
);
CREATE UNIQUE INDEX study_omics_i1 ON study_omics (study_id, omics_id);

CREATE VIEW study_omics_transposed AS
SELECT
study_id,
array_agg(ob.omics_id order by ob.omics_id)       AS omics_id,
array_agg(ob.omics_type order by ob.omics_id)     AS omics_type,
array_agg(ob.display_symbol order by ob.omics_id) AS display_symbol,
array_agg(ob.display_name order by ob.omics_id)   AS display_name
FROM study_omics
JOIN omics_base ob ON study_omics.omics_id = ob.omics_id
GROUP BY study_id
;

-- TODO (dmitri)
-- comment ON view study_omics_transposed is
-- E'@foreignKey (study_id) REFERENCES study (study_id)|@fieldName study|@foreignFieldName studyOmicsTransposed';


CREATE TABLE differential_expression  (
  study_id            int NOT NULL,
  omics_id            int NOT NULL REFERENCES omics_base,
  -- differential expression of this group (sample's annotation_value_id) vs. all other groups
  annotation_value_id int NOT NULL,
  pvalue              float,
  pvalue_adj          float,
  score               float,
  log2_foldchange     float,
  CONSTRAINT fk_study_id FOREIGN KEY (study_id) REFERENCES study (study_id) ON DELETE CASCADE,
  CONSTRAINT fk_sample_annotation_value FOREIGN KEY (annotation_value_id) REFERENCES annotation_value (annotation_value_id)
);
CREATE UNIQUE INDEX differential_expression_i1 ON differential_expression (study_id, annotation_value_id, omics_id);

-- TODO (dmitri)
-- CREATE OR REPLACE VIEW differential_expression_v
-- with (security_invoker = true)
-- AS
-- SELECT de.*, ob.omics_type, ob.display_symbol, ob.display_name, oa.linked_genes
-- FROM differential_expression de
-- JOIN omics_base ob ON de.omics_id = ob.omics_id
-- JOIN omics_all oa ON de.omics_id = oa.omics_id;
-- grant select ON differential_expression_v to postgraphile;

CREATE TABLE study_layer (
  study_layer_id serial PRIMARY KEY,
  study_id       int  NOT NULL,
  omics_type     omics_type,
  layer          text NOT NULL,
  CONSTRAINT fk_study_id FOREIGN KEY (study_id) REFERENCES study (study_id) ON DELETE CASCADE
);
CREATE UNIQUE INDEX study_layer_ui1 ON study_layer (study_id, layer, omics_type);


CREATE TABLE expression (
  study_layer_id   int       NOT NULL,
  omics_id         int       NOT NULL REFERENCES omics_base,
  -- for sparse data, REFERENCES study_sample.study_sample_id
  study_sample_ids integer[] NOT NULL,
  values           real[]    NOT NULL,
  CONSTRAINT fk_study_layer_id FOREIGN KEY (study_layer_id) REFERENCES study_layer (study_layer_id) ON DELETE CASCADE
);


-- TODO (dmitri)
-- partition by list (study_layer_id);

-- CREATE OR REPLACE PROCEDURE add_studylayer_partition(study_layer_id int)
-- LANGUAGE plpgsql
-- AS
-- $$
-- BEGIN
-- EXECUTE format(
--   'create table expression_%1$s
--   partition of expression
--   (
--   study_layer_id,
--   omics_id,
--   study_sample_ids,
--   values
--   )
--   for values in ( %1$s );
--   comment ON table expression_%1$s is ''@omit'';
--   CREATE UNIQUE INDEX  expression_%1$s_omics_uq ON expression_%1$s(omics_id);
--   ', study_layer_id);
-- END ;
-- $$;
