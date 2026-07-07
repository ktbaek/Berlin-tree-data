CREATE TABLE IF NOT EXISTS taxa (

    taxon_id SERIAL PRIMARY KEY,
    parent_taxon_id INTEGER REFERENCES taxa(taxon_id),
    family_id INTEGER NOT NULL REFERENCES families(family_id),
    epithet TEXT,
    is_hybrid BOOLEAN,

    taxon_level TEXT NOT NULL CHECK (
        taxon_level IN (
            'genus',
            'species',
            'subsp.',
            'var.',
            'f.',
            'cultivar',
            'sel.'
        )
    ),

    rank_order integer not null,
    show_cultivar_in_display BOOLEAN DEFAULT FALSE,

    CHECK (epithet IS NULL OR epithet <> ''),

    CHECK (
    (taxon_level = 'species' AND is_hybrid IS NOT NULL)
    OR
    (taxon_level <> 'species' AND is_hybrid IS NULL)
    ),

    -- genus rules
    CONSTRAINT genus_structure CHECK (

        (
            taxon_level = 'genus'
            AND parent_taxon_id IS NULL
            AND epithet IS NOT NULL
            AND epithet = INITCAP(epithet)
        )

        OR

        (
            taxon_level = 'species'
            AND parent_taxon_id IS NOT NULL
            AND epithet IS NOT NULL
        )

        OR

        (
            taxon_level = 'species'
            AND parent_taxon_id IS NOT NULL
            AND epithet IS NULL
            AND is_hybrid = true
        )

        OR

        (
            taxon_level IN ('subsp.', 'var.', 'f.', 'cultivar', 'sel.')
            AND parent_taxon_id IS NOT NULL
            AND epithet IS NOT NULL
        )


    )
);

CREATE UNIQUE INDEX unique_taxon
ON taxa (
    parent_taxon_id,
    taxon_level,
    COALESCE(epithet, ''),
    COALESCE(is_hybrid, FALSE)
);