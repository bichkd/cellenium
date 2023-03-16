
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
