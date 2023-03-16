-- TODO (dmitri)
-- this looks likely to need restructuring, with more general genomic feature type
-- also gene id references

CREATE TYPE omics_t AS ENUM ('gene', 'protein_antibody_tag', 'transcription_factor', 'region');

CREATE TABLE omics_base (
  omics_id       int4    PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  omics_type     omics_t NOT NULL,
  tax_id         int4    NOT NULL,
  display_symbol text    NOT NULL,
  display_name   text
  );

-- TODO do not like "shared" primary keys (dmitri)
CREATE TABLE omics_gene (
  gene_id         int4   NOT NULL REFERENCES omics_base PRIMARY KEY,
  ensembl_gene_id text   NOT NULL UNIQUE,
  entrez_gene_ids text[],
  hgnc_symbols    text[]
);

-- TODO do not like "shared" primary keys (dmitri)
CREATE TABLE omics_region (
  region_id      int4  NOT NULL REFERENCES omics_base PRIMARY KEY,
  chromosome     text  NOT NULL,
  start_position int4  NOT NULL,
  end_position   int4  NOT NULL,
  region         text  NOT NULL UNIQUE
);

CREATE TABLE omics_region_gene (
  region_id int4 NOT NULL REFERENCES omics_region,
  gene_id   int4 NOT NULL REFERENCES omics_gene,
  UNIQUE (region_id, gene_id)
);

-- TODO I had to add this to fix a postgraphile schema generation problem
-- COMMENT ON CONSTRAINT "omics_region_region_id_fkey" ON "public"."omics_region" IS E'@fieldName omics_region_newNameHere';

-- TODO do not like "shared" primary keys (dmitri)
CREATE TABLE omics_protein_antibody_tag (
  protein_antibody_tag_id int4 NOT NULL REFERENCES omics_base PRIMARY KEY,
  tax_id                  int4 NOT NULL,
  antibody_symbol         text NOT NULL,
  UNIQUE (tax_id, antibody_symbol)
);

CREATE TABLE omics_protein_antibody_tag_gene (
  protein_antibody_tag_id int4 NOT NULL REFERENCES omics_protein_antibody_tag,
  gene_id                 int4 NOT NULL REFERENCES omics_gene,
  UNIQUE (protein_antibody_tag_id, gene_id)
);

CREATE TABLE omics_transcription_factor (
  omics_id         int4 PRIMARY KEY REFERENCES omics_base,
  jaspar_matrix_id text NOT NULL UNIQUE
);

CREATE TABLE omics_transcription_factor_gene (
  transcription_factor_id int4 NOT NULL REFERENCES omics_transcription_factor,
  gene_id                 int4 NOT NULL REFERENCES omics_gene,
  UNIQUE (transcription_factor_id, gene_id)
);


CREATE TABLE study_omics (
  study_id       int4 NOT NULL REFERENCES study (study_id) ON DELETE CASCADE, -- TODO not sure that 'cascade' is appropriate here (large data)
  omics_id       int4 NOT NULL REFERENCES omics_base,
  -- indexing the h5ad .uns['protein_X'] matrix in this study
  h5ad_var_index int4 NOT NULL,
  -- TODO add another h5ad_col_index for second h5ad file (ATAC-seq)? Or better use h5ad format to combine atac-seq into same h5ad file
  -- TODO: AS --> should actually be fine as rna and atac have different omics_id
  -- region as seen in the actual study data before 'fuzzy' region matching with bedtools (expect same build, chromosome)
  region_start   int4,
  region_end     int4,
  UNIQUE (study_id, omics_id)
);

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

CREATE TABLE study_layer (
  study_layer_id int4    PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  study_id       int4    NOT NULL REFERENCES study ON DELETE CASCADE,
  layer          text    NOT NULL,
  omics_type     omics_t,
  UNIQUE (study_id, layer, omics_type)  -- TODO unqiue index on nullable column (unlikely to behave in a desirable manner)
);

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
