CREATE MATERIALIZED VIEW taxon_resolver AS
WITH RECURSIVE tree AS (

    -- Base: genus roots
    SELECT
        taxon_id,
        parent_taxon_id,
        taxon_level,

        /* ancestor ids */
        taxon_id AS genus_taxon_id,
        NULL::integer AS species_taxon_id,

        /* flattened names */
        epithet       AS genus,
        NULL::text    AS species,
        NULL::boolean AS is_hybrid,
        NULL::text    AS subsp,
        NULL::text    AS var,
        NULL::text    AS form,
        NULL::text    AS cultivar,
        NULL::text    AS selection

    FROM taxa
    WHERE taxon_level = 'genus'

    UNION ALL

    -- Recursive: children inherit all ancestor epithets, add their own
    SELECT
        t.taxon_id,
        t.parent_taxon_id,
        t.taxon_level,

        /* ancestor taxon ids */
        p.genus_taxon_id,
        CASE WHEN t.taxon_level = 'species'  THEN t.taxon_id  ELSE p.species_taxon_id
        END AS species_taxon_id,

        /* flattened names */
        p.genus,
        CASE WHEN t.taxon_level = 'species'  THEN t.epithet   ELSE p.species   END,
        CASE WHEN t.taxon_level = 'species'  THEN t.is_hybrid ELSE p.is_hybrid END,
        CASE WHEN t.taxon_level = 'subsp.'   THEN t.epithet   ELSE p.subsp     END,
        CASE WHEN t.taxon_level = 'var.'     THEN t.epithet   ELSE p.var       END,
        CASE WHEN t.taxon_level = 'f.'       THEN t.epithet   ELSE p.form      END,
        CASE WHEN t.taxon_level = 'cultivar' THEN t.epithet   ELSE p.cultivar  END,
        CASE WHEN t.taxon_level = 'sel.'     THEN t.epithet   ELSE p.selection END

    FROM taxa t
    JOIN tree p ON t.parent_taxon_id = p.taxon_id   -- skipped levels handled
                                                    -- by parent_taxon_id coalesce
                                                    -- at insert time
)
SELECT
    taxon_id,
    genus_taxon_id,
    species_taxon_id,
    genus,
    species,
    is_hybrid,
    subsp,
    var,
    form,
    cultivar,
    selection,
    taxon_level 

FROM tree
WITH DATA;

-- Fast point-lookup by resolved name columns (how staging will join)
CREATE UNIQUE INDEX taxon_resolver_id_idx
    ON taxon_resolver (taxon_id);

CREATE INDEX taxon_resolver_lookup_idx
    ON taxon_resolver (genus, species, is_hybrid, subsp, var, form, cultivar);

CREATE INDEX taxon_resolver_species_idx
    ON taxon_resolver (genus, species, is_hybrid);

-- Refresh after any bulk taxonomy change
-- REFRESH MATERIALIZED VIEW CONCURRENTLY taxon_resolver;
