CREATE OR REPLACE VIEW rarity AS
WITH genera_with_species AS (

    SELECT DISTINCT genus_taxon_id
    FROM taxon_resolver
    WHERE species_taxon_id IS NOT NULL

),

rare_taxa AS (

    SELECT
        r.genus_taxon_id,
        r.species_taxon_id,

        CASE
            WHEN COUNT(*) = 1 THEN 1
            WHEN COUNT(*) BETWEEN 2 AND 5 THEN 2
            WHEN COUNT(*) BETWEEN 6 AND 10 THEN 3
        END AS rarity

    FROM trees t
    JOIN taxon_resolver r
      ON r.taxon_id = t.taxon_id

    GROUP BY 1, 2

),

filtered_rare_taxa AS (

    SELECT rt.*
    FROM rare_taxa rt

    LEFT JOIN genera_with_species gws
      ON gws.genus_taxon_id = rt.genus_taxon_id

    WHERE NOT (
        rt.species_taxon_id IS NULL
        AND gws.genus_taxon_id IS NOT NULL
    )

)

SELECT
    r.taxon_id,
    frt.rarity,
    r.genus,
    r.species,
    r.is_hybrid

FROM taxon_resolver r

JOIN filtered_rare_taxa frt
  ON frt.species_taxon_id IS NOT DISTINCT FROM r.species_taxon_id
 AND frt.genus_taxon_id IS NOT DISTINCT from r.genus_taxon_id

WHERE frt.rarity IS NOT NULL;

