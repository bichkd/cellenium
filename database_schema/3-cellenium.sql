CREATE TABLE study
(
    study_id                serial primary key,
    study_name              text not null,
    description             text,
    cluster_color_map       jsonb,
    -- TODO remove default once this data is set by study importer
    tissue_ncit_ids         text[] default array ['C12393'],
    --tissue_ncit_labels      text[],
    disease_mesh_ids        text[],
    --disease_mesh_labels     text[],
    cell_ontology_ids       text[],
    --cell_ontology_labels    text[],
    organism_tax_id         text,
    --organism_label          text,
    --ontology_ids_with_parents text[]   for search


    --attributes              text[],

    cluster_hulls           jsonb,
    plot_coords             jsonb,
    h5adfile_modified_date  timestamptz,
    import_status           text,
    import_status_updated   timestamptz,
    attribute_value_freq    jsonb,
    cell_count              int,
--     qc_status               text,
--     qc_result               jsonb,

    -- for subsampling:
    projection_cell_coords  jsonb,
    projection_cell_indices jsonb
);


drop table if exists omics_base cascade;
CREATE TYPE omics_type AS ENUM ('gene', 'protein_antibody_tag', 'transcription_factor', 'region');

CREATE TABLE omics_base
(
    omics_id       serial primary key,
    omics_type     omics_type not null,
    tax_id         int        not null,
    display_symbol text       not null,
    display_name   text
);

CREATE TABLE omics_gene
(
    gene_id         int  not null references omics_base primary key,
    ensembl_gene_id text not null,
    entrez_gene_ids text[],
    hgnc_symbols    text[]
);
create unique index omics_gene_1 on omics_gene (ensembl_gene_id);

-- cite-seq
CREATE TABLE omics_protein_antibody_tag
(
    protein_antibody_tag_id int not null references omics_base primary key,
    -- kinda duplicated to display_symbol etc., but lets have it for now:
    antibody_symbol         text,
    antibody_name           text
);
create unique index omics_protein_antibody_tag_1 on omics_protein_antibody_tag (antibody_symbol);


CREATE TABLE omics_protein_antibody_tag_gene
(
    protein_antibody_tag_id int not null references omics_protein_antibody_tag,
    gene_id                 int not null references omics_gene
);
create unique index omics_protein_antibody_tag_gene_1 on omics_protein_antibody_tag_gene (protein_antibody_tag_id, gene_id);

CREATE TABLE omics_transcription_factor
(
    omics_id         int  not null references omics_base primary key,
    jaspar_matrix_id text not null
);
create unique index omics_transcription_factor_1 on omics_transcription_factor (jaspar_matrix_id);


CREATE TABLE omics_transcription_factor_gene
(
    transcription_factor_id int not null references omics_transcription_factor,
    gene_id                 int not null references omics_gene
);
create unique index omics_transcription_factor_gene_1 on omics_transcription_factor_gene (transcription_factor_id, gene_id);


create view omics_element as
select b.omics_id,
       b.omics_type,
       b.tax_id,
       b.display_symbol,
       b.display_name,
       og.ensembl_gene_id,
       coalesce(
               array_agg(opatg.gene_id),
               array_agg(otfg.gene_id)
           ) linked_genes
from omics_base b
         left join omics_gene og on b.omics_id = og.gene_id
         left join omics_protein_antibody_tag_gene opatg on b.omics_id = opatg.protein_antibody_tag_id
         left join omics_transcription_factor_gene otfg on b.omics_id = otfg.transcription_factor_id
group by b.omics_id, b.omics_type, b.tax_id, b.display_symbol, b.display_name,
         og.ensembl_gene_id;

/*
-- TODO add omics_region... tables, same style

    build            text,
    region_chr       text,
    region_start     int,
    region_end       int
);
--create unique index omics_element_uq_region on omics (tax_id, build, region_chr, region_start, region_end);
CREATE TABLE omics_region_gene
(
    omics_id        int not null,
    constraint fk_omics_element_region_index
        FOREIGN KEY (omics_id)
            REFERENCES omics (omics_id) ON DELETE CASCADE,
    gene            text,
    ensembl_gene_id text,
    evidence        text,
    evidence_score  real,
    evidence_source text
);
create unique index omics_region_uq on omics_region_gene (omics_id, gene, evidence, evidence_source);

 */

-- e.g. in annotation category 'cell ontology name'
CREATE TABLE annotation
(
    annotation_id serial primary key,
    h5ad_column   text not null,
    display_group text not null
);
create unique index annotation_1 on annotation (h5ad_column);

-- e.g. in annotation category value 'lymphocyte'
CREATE TABLE annotation_value
(
    annotation_value_id serial primary key,
    annotation_id       int  not null,
    constraint fk_annotation
        FOREIGN KEY (annotation_id)
            REFERENCES annotation (annotation_id),

    h5ad_value          text not null,
    display_value       text not null,
    color               text
);
create unique index annotation_value_1 on annotation_value (annotation_id, h5ad_value);

CREATE TABLE study_sample_annotation_ui
(
    study_id                           int     not null,
    constraint fk_study_id
        FOREIGN KEY (study_id)
            REFERENCES study (study_id) ON DELETE CASCADE,

    annotation_id                      int     not null,
    constraint fk_annotation
        FOREIGN KEY (annotation_id)
            REFERENCES annotation (annotation_id),

    is_primary                         boolean not null,
    ordering                           int     not null,
    differential_expression_calculated boolean not null
);

CREATE TABLE study_sample
(
    study_id            int     not null,
    constraint fk_study_id
        FOREIGN KEY (study_id)
            REFERENCES study (study_id) ON DELETE CASCADE,

    study_sample_id     int     not null,
    constraint pk_study_sample primary key (study_id, study_sample_id),

    h5ad_obs_index      int     not null,
    display_subsampling boolean not null
);
--create unique index study_sample_i1 on study_sample (study_id, study_sample_id);

CREATE TABLE study_sample_annotation
(
    study_id            int not null,
    constraint fk_study_id
        FOREIGN KEY (study_id)
            REFERENCES study (study_id) ON DELETE CASCADE,

    study_sample_id     int not null,
    constraint fk_study_sample
        FOREIGN KEY (study_id, study_sample_id)
            REFERENCES study_sample (study_id, study_sample_id) ON DELETE CASCADE,


    annotation_value_id int not null,
    constraint fk_sample_annotation_value
        FOREIGN KEY (annotation_value_id)
            REFERENCES annotation_value (annotation_value_id)
);

CREATE TABLE study_omics
(
    study_id       int not null,
    constraint fk_study_id
        FOREIGN KEY (study_id)
            REFERENCES study (study_id) ON DELETE CASCADE,

    omics_id       int not null references omics_base,

    -- indexing the h5ad .uns['protein_X'] matrix in this study
    h5ad_var_index int not null,
    -- TODO add another h5ad_col_index for second h5ad file (ATAC-seq)? Or better use h5ad format to combine atac-seq into same h5ad file

    -- region as seen in the actual study data before 'fuzzy' region matching with bedtools (expect same build, chromosome)
    region_start   int,
    region_end     int
);

CREATE TABLE differential_expression
(
    study_id            int not null,
    constraint fk_study_id
        FOREIGN KEY (study_id)
            REFERENCES study (study_id) ON DELETE CASCADE,
    omics_id            int not null references omics_base,

    /* can add this, but its redundant
    annotation_id       int not null,
    constraint fk_annotation
        FOREIGN KEY (annotation_id)
            REFERENCES annotation (annotation_id),
     */

    -- differential expression of this group (sample's annotation_value_id) vs. all other groups
    annotation_value_id int not null,
    constraint fk_sample_annotation_value
        FOREIGN KEY (annotation_value_id)
            REFERENCES annotation_value (annotation_value_id),

    pvalue              float,
    pvalue_adj          float,
    score               float,
    log2_foldchange     float
);
create unique index differential_expression_i1 on differential_expression (study_id, annotation_value_id, omics_id);

CREATE TABLE study_layer
(
    study_layer_id serial primary key,
    study_id       int        not null,
    constraint fk_study_id
        FOREIGN KEY (study_id)
            REFERENCES study (study_id) ON DELETE CASCADE,
    omics_type     omics_type not null,
    layer          text       not null

);
create unique index study_layer_ui1 on study_layer (study_id, layer);


CREATE TABLE expression
(
    study_layer_id   int       not null,
    constraint fk_study_layer_id
        FOREIGN KEY (study_layer_id)
            REFERENCES study_layer (study_layer_id) ON DELETE CASCADE,
    omics_id         int       not null references omics_base,

    -- for sparse data, references study_sample.study_sample_id
    study_sample_ids integer[] not null,
    values           real[]    not null

) partition by list (study_layer_id);

-- TODO procedure for creating new partition, and unique index omics_id inside

