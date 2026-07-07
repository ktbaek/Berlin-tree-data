CREATE VIEW taxon_primary_common_names AS
SELECT
    taxon_id,
    MIN(common_name) AS common_name
FROM taxon_common_names
GROUP BY taxon_id;