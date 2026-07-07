CREATE OR REPLACE VIEW taxon_lookup_for_map AS
SELECT DISTINCT
  r.taxon_id,
  r.genus_taxon_id,
  r.species_taxon_id,
  tdn.scientific_name_short as scientific_name,
  tdn.scientific_name_medium as display_name,
  tdn.cultivar,
  tdn.common_name,
  r.genus as genus_name,
  gen_cn.common_name as genus_common_name,
  sp_cn.common_name as species_common_name,
  tt.treetype,
  tt.fruit,
  rt.rarity,
  ri.icon_id,
  c.fillcolor
  

FROM taxon_resolver r
  
LEFT JOIN taxon_display_names tdn 
  ON r.taxon_id = tdn.taxon_id

LEFT JOIN taxon_primary_common_names gen_cn
  ON gen_cn.taxon_id = r.genus_taxon_id

LEFT JOIN taxon_primary_common_names sp_cn
  ON sp_cn.taxon_id = r.species_taxon_id

LEFT JOIN resolved_icons ri 
  ON r.taxon_id = ri.taxon_id

LEFT JOIN species_colors c 
  ON r.taxon_id = c.taxon_id

LEFT JOIN taxon_treetype tt
  ON r.taxon_id = tt.taxon_id

LEFT JOIN rarity rt
  ON r.taxon_id = rt.taxon_id;


