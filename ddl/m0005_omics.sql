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

CREATE TABLE study_layer (
  study_layer_id serial PRIMARY KEY,
  study_id       int  NOT NULL,
  omics_type     omics_type,
  layer          text NOT NULL,
  CONSTRAINT fk_study_id FOREIGN KEY (study_id) REFERENCES study (study_id) ON DELETE CASCADE
);
CREATE UNIQUE INDEX study_layer_ui1 ON study_layer (study_id, layer, omics_type);
