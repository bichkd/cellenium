-- TODO short-cicruit visibility for now (dmitri)
CREATE OR REPLACE VIEW study_visible_currentuser AS SELECT s.study_id FROM study s;
CREATE OR REPLACE VIEW study_administrable_currentuser AS SELECT s.study_id FROM study s;

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

-- contains all samples which appear in at least one projection
CREATE OR REPLACE VIEW study_sample_annotation_subsampling AS
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
