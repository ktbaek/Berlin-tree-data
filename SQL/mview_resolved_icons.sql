CREATE MATERIALIZED VIEW resolved_icons AS

SELECT
    tx.taxon_id,

    CASE

        -- explicit icon always wins
        WHEN ti_direct.icon_id IS NOT NULL
        THEN ti_direct.icon_id

        -- only infra taxa may fallback
        WHEN tx.taxon_level IN ('subsp.', 'var.', 'f.', 'cultivar', 'sel.')

         -- sparse-table default:
         -- no row = fallback allowed
         AND COALESCE(ti_direct.allow_fallback, TRUE)

        THEN ti_species.icon_id

        ELSE NULL

    END AS icon_id

FROM taxa tx

LEFT JOIN taxon_icons ti_direct
  ON ti_direct.taxon_id = tx.taxon_id

LEFT JOIN taxon_resolver r
  ON r.taxon_id = tx.taxon_id

LEFT JOIN taxon_icons ti_species
  ON ti_species.taxon_id = r.species_taxon_id;