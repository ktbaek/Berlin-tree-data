
INSERT INTO trees (
    updated_at,
    uuid,
    taxon_id,
    sex,
    lat,
    lon,
    district_id,
    planting_year,
    protected,
    special,
    iconic,
    fruit,
    is_duplicate_location,
    raw_dansk_navn,
    raw_slaegtsnavn
)
SELECT
    rt.updated_at,
    rt.uuid,
    tx.taxon_id,
    rt.sex,
    rt.lat,
    rt.lon,
    d.district_id,
    rt.planting_year,
    rt.protected,
    COALESCE(rt.special, FALSE),
    COALESCE(rt.iconic, FALSE),
    rt.fruit,
    rt.is_duplicate_location,
    rt.raw_dansk_navn,
    rt.raw_slaegtsnavn

FROM raw_trees_2026 rt

LEFT JOIN districts d
    ON d.district_name = rt.district_name

left JOIN genera g
    ON g.genus_name = rt.genus

 LEFT JOIN taxa tx
  ON tx.genus_id = g.genus_id

 AND tx.is_hybrid IS NOT DISTINCT FROM rt.is_hybrid

 AND (
    (
        tx.taxon_level = 'infraspecies'
        AND tx.species_epithet IS NOT DISTINCT FROM rt.species_epithet
        AND tx.infraspecies_name IS NOT DISTINCT FROM rt.infraspecies_name
        AND tx.infraspecies_type IS NOT DISTINCT FROM rt.infraspecies_type
    )

    OR
    
    (
        tx.taxon_level = 'species'
        AND tx.species_epithet IS NOT DISTINCT FROM rt.species_epithet
        AND rt.infraspecies_name IS NULL
        AND rt.infraspecies_type IS NULL
    )

    OR

    (
        tx.taxon_level = 'genus'
        AND rt.species_epithet IS NULL
        AND rt.infraspecies_name IS NULL
        AND rt.infraspecies_type IS NULL
    )
 );