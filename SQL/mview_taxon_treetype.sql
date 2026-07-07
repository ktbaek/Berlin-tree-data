CREATE MATERIALIZED VIEW taxon_treetype AS
WITH parsed AS (
    SELECT
        t.taxon_id,
        CASE 
             WHEN t.tree_type = 'Obstbäume' THEN TRUE
             ELSE FALSE
        END AS fruit,
        CASE 
            WHEN t.tree_type IN ('Laubbäume', 'Obstbäume') THEN 1
            WHEN t.tree_type = 'Nadelbäume' THEN 2
            WHEN t.tree_type IN ('Sträucher', 'Großsträucher') THEN 3
            ELSE NULL
        END AS treetype
    FROM trees t
)    
SELECT DISTINCT ON (t.taxon_id)
    t.taxon_id,
    -- In case different trees with same taxon_id has different values
    FIRST_VALUE(t.treetype) OVER (
        PARTITION BY t.taxon_id
        ORDER BY (t.treetype IS NOT NULL) DESC
    ) AS treetype,
    -- In case different trees with same taxon_id has different values
    FIRST_VALUE(t.fruit) OVER (
        PARTITION BY t.taxon_id
        ORDER BY (t.fruit = FALSE) DESC
    ) AS fruit
FROM parsed t
WHERE t.taxon_id IS NOT NULL
ORDER BY t.taxon_id;

CREATE UNIQUE INDEX idx_taxon_treetype ON taxon_treetype (taxon_id);




