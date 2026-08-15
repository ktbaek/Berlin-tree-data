create or replace VIEW taxon_primary_common_names AS
SELECT DISTINCT ON (taxon_id)
    taxon_id,
    common_name
FROM taxon_common_names
ORDER BY taxon_id, primary_name DESC, common_name ASC;