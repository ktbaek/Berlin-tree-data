-- genus
INSERT INTO taxa (
    parent_taxon_id,
    family_id,
    epithet,
    is_hybrid,
    taxon_level,
    rank_order
)

SELECT DISTINCT
    null::INTEGER,
    f.family_id,
    rt.genus,
    null::boolean,
    'genus',
    1

FROM raw_taxa rt

JOIN families f ON f.family_name = rt.family

WHERE rt.genus IS NOT NULL

ON CONFLICT DO NOTHING;

-- species
INSERT INTO taxa (
    parent_taxon_id,
    family_id,
    epithet,
    is_hybrid,
    taxon_level,
    rank_order
)

SELECT DISTINCT
    g.taxon_id,
    f.family_id,
    rt.species,
    rt.is_hybrid,
    'species',
    2

FROM raw_taxa rt

JOIN families f ON f.family_name = rt.family

JOIN taxa g
    ON g.taxon_level = 'genus'
   AND g.epithet = rt.genus

WHERE rt.taxon_level = 'species'

ON CONFLICT DO NOTHING;

-- subspecies
INSERT INTO taxa (
    parent_taxon_id,
    family_id,
    epithet,
    is_hybrid,
    taxon_level,
    rank_order
)

SELECT DISTINCT
    s.taxon_id,
    f.family_id,
    rt.subsp,
    null::boolean,
    'subsp.',
    3

FROM raw_taxa rt

JOIN families f
  ON f.family_name = rt.family

JOIN taxa g
  ON g.taxon_level = 'genus'
 AND g.epithet = rt.genus

JOIN taxa s
  ON s.taxon_level = 'species'
 AND s.parent_taxon_id = g.taxon_id
 AND s.epithet IS NOT DISTINCT FROM rt.species
 AND s.is_hybrid IS NOT DISTINCT FROM rt.is_hybrid

WHERE rt.subsp IS NOT NULL

ON CONFLICT DO NOTHING;

-- variety
INSERT INTO taxa (
    parent_taxon_id,
    family_id,
    epithet,
    is_hybrid,
    taxon_level,
    rank_order
)

SELECT DISTINCT

    COALESCE(ss.taxon_id, s.taxon_id),
	f.family_id,
	rt.var,
	null::boolean,
	'var.',
	4

FROM raw_taxa rt

JOIN families f
  ON f.family_name = rt.family

JOIN taxa g
  ON g.taxon_level = 'genus'
 AND g.epithet = rt.genus

JOIN taxa s
  ON s.taxon_level = 'species'
 AND s.parent_taxon_id = g.taxon_id
 AND s.epithet IS NOT DISTINCT FROM rt.species
 AND s.is_hybrid IS NOT DISTINCT FROM rt.is_hybrid

LEFT JOIN taxa ss
  ON ss.taxon_level = 'subsp.'
 AND ss.parent_taxon_id = s.taxon_id
 AND ss.epithet IS NOT DISTINCT FROM rt.subsp

WHERE rt.var IS NOT NULL

ON CONFLICT DO NOTHING;

-- forma
INSERT INTO taxa (
    parent_taxon_id,
    family_id,
    epithet,
    is_hybrid,
    taxon_level,
    rank_order
)

SELECT DISTINCT

    COALESCE(v.taxon_id, ss.taxon_id, s.taxon_id),
	f.family_id,
	rt.form,
	null::boolean,
	'f.',
	5

FROM raw_taxa rt

JOIN families f
  ON f.family_name = rt.family

JOIN taxa g
  ON g.taxon_level = 'genus'
 AND g.epithet = rt.genus

JOIN taxa s
  ON s.taxon_level = 'species'
 AND s.parent_taxon_id = g.taxon_id
 AND s.epithet IS NOT DISTINCT FROM rt.species
 AND s.is_hybrid IS NOT DISTINCT FROM rt.is_hybrid

LEFT JOIN taxa ss
  ON ss.taxon_level = 'subsp.'
 AND ss.parent_taxon_id = s.taxon_id
 AND ss.epithet IS NOT DISTINCT FROM rt.subsp

LEFT JOIN taxa v
  ON v.taxon_level = 'var.'
 AND v.parent_taxon_id = COALESCE(ss.taxon_id, s.taxon_id)
 AND v.epithet IS NOT DISTINCT FROM rt.var

WHERE rt.form IS NOT NULL

ON CONFLICT DO NOTHING;

-- cultivar
INSERT INTO taxa (
    parent_taxon_id,
    family_id,
    epithet,
    is_hybrid,
    taxon_level,
    rank_order
)

SELECT DISTINCT

    COALESCE(fm.taxon_id,
             v.taxon_id,
             ss.taxon_id,
             s.taxon_id),
	f.family_id,
	rt.cultivar,
	null::boolean,
	'cultivar',
	6

FROM raw_taxa rt

JOIN families f
  ON f.family_name = rt.family

JOIN taxa g
  ON g.taxon_level = 'genus'
 AND g.epithet = rt.genus

JOIN taxa s
  ON s.taxon_level = 'species'
 AND s.parent_taxon_id = g.taxon_id
 AND s.epithet IS NOT DISTINCT FROM rt.species
 AND s.is_hybrid IS NOT DISTINCT FROM rt.is_hybrid

LEFT JOIN taxa ss
  ON ss.taxon_level = 'subsp.'
 AND ss.parent_taxon_id = s.taxon_id
 AND ss.epithet IS NOT DISTINCT FROM rt.subsp

LEFT JOIN taxa v
  ON v.taxon_level = 'var.'
 AND v.parent_taxon_id = COALESCE(ss.taxon_id, s.taxon_id)
 AND v.epithet IS NOT DISTINCT FROM rt.var

LEFT JOIN taxa fm
  ON fm.taxon_level = 'f.'
 AND fm.parent_taxon_id = COALESCE(v.taxon_id,
                                   ss.taxon_id,
                                   s.taxon_id)
 AND fm.epithet IS NOT DISTINCT FROM rt.form

WHERE rt.cultivar IS NOT NULL

ON CONFLICT DO NOTHING;

-- common names
INSERT INTO taxon_common_names (
    taxon_id,
    common_name
)

SELECT
    r.taxon_id,
    cn.common_name

FROM raw_taxon_common_names cn

JOIN taxon_resolver r
  ON r.genus IS NOT DISTINCT FROM cn.genus
 AND r.species IS NOT DISTINCT FROM cn.species
 AND r.is_hybrid IS NOT DISTINCT FROM cn.is_hybrid
 AND r.subsp IS NOT DISTINCT FROM cn.subsp
 AND r.var IS NOT DISTINCT FROM cn.var
 AND r.form IS NOT DISTINCT FROM cn.form
 AND r.cultivar IS NOT DISTINCT FROM cn.cultivar;

 -- trees
 INSERT INTO trees (
    gisid,
    updated_at,
    dataset,
    taxon_id,
    lat,
    lon,
    place_id,
    planting_year,
    tree_type,
    trunk_circ,
    tree_height,
    is_duplicate_location
)
SELECT
    rt.gisid,
    rt.updated_at,
    rt.dataset,
    r.taxon_id,
    rt.lat,
    rt.lon,
    p.place_id,
    rt.planting_year,
    rt.tree_type,
    rt.trunk_circ,
    rt.tree_height,
    rt.is_duplicate_location

FROM raw_trees_2026 rt

LEFT JOIN taxon_resolver r
  ON r.genus IS NOT DISTINCT FROM rt.genus
 AND r.species IS NOT DISTINCT FROM rt.species
 AND r.is_hybrid IS NOT DISTINCT FROM rt.is_hybrid
 AND r.subsp IS NOT DISTINCT FROM rt.subsp
 AND r.var IS NOT DISTINCT FROM rt.var
 AND r.form IS NOT DISTINCT FROM rt.form
 AND r.cultivar IS NOT DISTINCT FROM rt.cultivar

LEFT JOIN districts d USING (district_name)

LEFT JOIN places p 
  ON rt.place_name IS NOT DISTINCT FROM p.place_name
 AND d.district_id = p.district_id


-- icons
INSERT INTO taxon_icons (
    taxon_id,
    icon_id,
    allow_fallback
)
SELECT
    r.taxon_id,
    ri.icon_id,
    ri.allow_fallback

FROM raw_taxon_icons ri

JOIN taxon_resolver r
  ON r.genus IS NOT DISTINCT FROM ri.genus
 AND r.species IS NOT DISTINCT FROM ri.species
 AND r.is_hybrid IS NOT DISTINCT FROM ri.is_hybrid
 AND r.subsp IS NOT DISTINCT FROM ri.subsp
 AND r.var IS NOT DISTINCT FROM ri.var
 AND r.form IS NOT DISTINCT FROM ri.form
 AND r.selection IS NOT DISTINCT FROM ri.selection
 AND r.cultivar IS NOT DISTINCT FROM ri.cultivar

 