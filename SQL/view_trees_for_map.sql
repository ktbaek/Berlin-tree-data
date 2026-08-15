CREATE OR REPLACE VIEW trees_for_map AS

WITH ranked AS (
    SELECT
        t.*,
        ROW_NUMBER() 
        OVER (PARTITION BY
            ROUND(t.lon::numeric, 6),
            ROUND(t.lat::numeric, 6)
            ORDER BY
            (t.taxon_id IS NOT NULL) DESC,
            (t.planting_year IS NOT NULL) DESC,
            t.gisid
        ) AS rn
    FROM trees t
)

SELECT
    t.gisid,
    tn.tree_number,
    t.taxon_id,
    t.lat,
    t.lon,
    t.planting_year,
    cast(t.tree_height AS INT)

FROM ranked t

LEFT JOIN tree_numbers tn USING (gisid)

WHERE (t.is_duplicate_location = FALSE OR t.rn = 1);