CREATE VIEW taxon_display_names AS

WITH base AS (
    SELECT
        r.taxon_id,
        r.taxon_level,
        r.genus,
        r.species,
        r.is_hybrid,
        r.subsp,
        r.var,
        r.form,
        r.cultivar,
        r.selection,
        tpn.common_name

    FROM taxon_resolver r 
    LEFT JOIN taxon_primary_common_names tpn USING (taxon_id)
)

SELECT
    b.taxon_id,

    -- Scientific names
    TRIM(
        COALESCE(b.genus, '') ||

        CASE
            WHEN b.is_hybrid THEN ' hybr.'
            WHEN b.taxon_level = 'genus' THEN ' sp.'
            ELSE ''
        END ||

        CASE
            WHEN b.species IS NOT NULL
            THEN ' ' || b.species
            ELSE ''
        END
    ) AS scientific_name_short,

    TRIM(
        COALESCE(b.genus, '') ||

        CASE
            WHEN b.is_hybrid THEN ' hybr.'
            WHEN b.taxon_level = 'genus' THEN ' sp.'
            ELSE ''
        END ||

        CASE
            WHEN b.species IS NOT NULL
            THEN ' ' || b.species
            ELSE ''
        END ||

        CASE
            WHEN b.subsp IS NOT NULL
            THEN ' ssp. ' || b.subsp
            ELSE ''
        END ||

        CASE
            WHEN b.var IS NOT NULL
            THEN ' var. ' || b.var
            ELSE ''
        END ||

        CASE
            WHEN b.form IS NOT NULL
            THEN ' f. ' || b.form
            ELSE ''
        END ||

        CASE
            WHEN b.selection IS NOT NULL
            THEN ' sel. ' || b.selection
            ELSE ''
        END

    ) AS scientific_name_medium,

    -- Cultivar
    CASE
        WHEN b.taxon_level = 'cultivar'
        THEN b.cultivar
        ELSE NULL
    END as cultivar,

    -- Raw common name
    b.common_name,
    b.taxon_level

    -- Display name (cultivar logic)
    /* CASE
    WHEN b.base_common_name IS NOT NULL
        AND b.taxon_level = 'infraspecies'
        AND b.infraspecies_type = 'cultivar'
        AND b.show_cultivar_in_display
    THEN b.base_common_name || ' ''' || b.infraspecies_name || ''''
    ELSE b.base_common_name
    END AS display_common_name */

FROM base b;