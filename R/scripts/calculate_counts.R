# source functions
r_files <- list.files("R/functions", pattern = "\\.R$", full.names = TRUE)
invisible(lapply(r_files, source))

this_year <- as.integer(format(Sys.Date(), "%Y"))

trees <- as_tibble(DBI::dbGetQuery(con, 
"
SELECT 
t.planting_year,
tx.taxon_id,
tx.genus_taxon_id,
tx.species_taxon_id,
tx.scientific_name,
tx.treetype,
tx.rarity,
tx.fruit
FROM trees_for_map t
LEFT JOIN taxon_lookup_for_map tx
on t.taxon_id = tx.taxon_id
"))

simple_counts <- list(
  "age-old"  = sum((this_year - trees$planting_year) > 100, na.rm = TRUE),
  "age-young" = sum((this_year - trees$planting_year) <= 5, na.rm = TRUE),
  "fruit"    = sum(trees$fruit == TRUE, na.rm = TRUE),
  "treetype" = trees |> 
    count(treetype) |> 
    filter(!is.na(treetype)) |>
    deframe() |> 
    as.list(),
  "rarity"   = trees |> 
    count(rarity) |> 
    filter(!is.na(rarity)) |>
    deframe() |>
    as.list()
)

write_json(simple_counts, "../website/src/assets/dataset/simple_count.json", pretty = TRUE, auto_unbox = TRUE)

genus_df <- trees |> filter(!is.na(genus_taxon_id)) |> count(genus_taxon_id)
as.list(setNames(genus_df$n, genus_df$genus_taxon_id)) |> 
  write_json("../website/src/assets/dataset/genus_count.json", pretty = TRUE, auto_unbox = TRUE)

species_df <- trees |> filter(!is.na(species_taxon_id)) |> count(species_taxon_id)
as.list(setNames(species_df$n, species_df$species_taxon_id)) |> 
  write_json("../website/src/assets/dataset/species_count.json", pretty = TRUE, auto_unbox = TRUE)
    
  
