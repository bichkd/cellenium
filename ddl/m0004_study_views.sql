-- TODO short-cicruit visibility for now (dmitri)
CREATE OR REPLACE VIEW study_visible_currentuser AS SELECT s.study_id FROM study s;
CREATE OR REPLACE VIEW study_administrable_currentuser AS SELECT s.study_id FROM study s;

CREATE OR REPLACE VIEW study_sample_projection_subsampling_transposed AS
SELECT
study_id,
projection_type,
modality,
array_agg(sample_id ORDER BY sample_id) AS sample_id,
array_agg(projection ORDER BY sample_id) AS projection
FROM projection
WHERE display_subsampling = true
GROUP BY study_id, projection_type, modality
;

-- TODO (dmitri)
-- comment ON view study_sample_projection_subsampling_transposed is
-- E'@foreignKey (study_id) REFERENCES study (study_id)|@fieldName study|@foreignFieldName studySampleProjectionSubsamplingTransposed';

-- contains all samples which appear in at least one projection
CREATE OR REPLACE VIEW study_sample_annotation_subsampling AS
SELECT
ssa.study_id,
ssa.annotation_value_id,
array_agg(DISTINCT ssp.sample_id) sample_ids
FROM sample_annotation ssa
CROSS JOIN unnest(ssa.sample_ids) q_sample_id
JOIN projection ssp ON ssp.study_id = ssa.study_id AND ssp.sample_id = q_sample_id
WHERE ssp.display_subsampling = true
GROUP BY ssa.study_id, ssa.annotation_value_id
;

-- TODO (dmitri)
-- comment ON view study_sample_annotation_subsampling is
-- E'@foreignKey (study_id) REFERENCES study (study_id)|@fieldName study|@foreignFieldName studySampleAnnotationSubsampling';
