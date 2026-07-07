
# get data from db
df <- as_tibble(DBI::dbGetQuery(con, 
"
WITH trees AS (

SELECT
tfm.gisid,
t.dataset,
t.taxon_id,
t.planting_year,
t.tree_type,
t.trunk_circ,
t.tree_height,
t.place_id

FROM trees_for_map tfm
LEFT JOIN trees t USING (gisid)
)

SELECT 
t.*,
d.district_name,
tx.genus_taxon_id,
tx.species_taxon_id,
tx.scientific_name,
tx.common_name,
tx.species_common_name,
tx.genus_name,
tx.genus_common_name,
r.subsp,
r.var,
r.form,
r.cultivar

FROM trees t
LEFT JOIN taxon_lookup_for_map tx USING (taxon_id)
LEFT JOIN taxon_resolver r USING (taxon_id)
LEFT JOIN places p USING (place_id)
LEFT JOIN districts d USING (district_id)
"))


total_count <- nrow(df)
total_known <- sum(!is.na(df$taxon_id))

# Summary per species
species_summary <- df %>%
  filter(!is.na(species_taxon_id)) |>
  group_by(species_taxon_id) %>%
  summarise(
    n_species = n(),
    yearUnknown = sum(is.na(planting_year)),
    oldestYear = ifelse(n_species == yearUnknown, NA_integer_, min(planting_year, na.rm = TRUE)),
    newestYear = ifelse(n_species == yearUnknown, NA_integer_, max(planting_year, na.rm = TRUE))
  ) |>
  mutate(
    totalRank = rank(- n_species),
    totalRank = ifelse(totalRank > 10, NA_integer_, as.integer(totalRank)),
    percentageOfTotal = round(n_species / total_known * 100, 1)
    ) 

genus_counts <- df |>
  filter(!is.na(genus_taxon_id)) |>
  group_by(genus_taxon_id) |> 
  summarize(
    n_genus = n(),
    n_species_na = sum(is.na(species_taxon_id))
  )

genus_summary <- df |>
  filter(!is.na(genus_taxon_id)) |>
  group_by(genus_taxon_id, species_taxon_id) |>
  summarize(n_species = n()) |> 
  left_join(genus_counts, by = "genus_taxon_id", relationship = "many-to-one") |> 
  mutate(
    percentageOfGenus = round(n_species / n_genus * 100, 1),
    percentageOfGenusUnknown = round(n_species_na / n_genus * 100, 1),
  ) |> 
  filter(!is.na(species_taxon_id)) |> 
  mutate(genusRank = as.integer(rank(-n_species))) |> # grouped by genus_id from join
  select(- starts_with("n_"))


# Counts per species per neighborhood
species_districts <- df %>%
  filter(!is.na(district_name)) |> 
  add_count(district_name, name = "n_district") |>
  add_count(species_taxon_id, district_name, name = "n_district_species") |> 
  select(species_taxon_id, district_name, n_district_species, n_district) |>
  distinct() |> 
  left_join(
    species_summary |> select(species_taxon_id, n_species), 
            by = "species_taxon_id", relationship = "many-to-one"
    ) |> 
  group_by(species_taxon_id) |> 
  mutate(
    enrichment = round((n_district_species / n_species) / (n_district / total_count), 1),
    percentageOfTrees = round(n_district_species / n_district * 100, 1)
  ) |> 
  select(-n_district, -n_species) |> 
  rename(
    name = district_name,
    count = n_district_species
  ) |> 
  group_by(species_taxon_id) %>%
  reframe(districtStats = list(pick(everything()))) 
  
# Counts per species per infraspecies
species_infra <- df %>%
  filter(!is.na(species_taxon_id), species_taxon_id != taxon_id) |>
  group_by(species_taxon_id, taxon_id, subsp, var, form, cultivar) %>%
  summarise(
    n_taxon_id = n(),
    .groups = "drop"
  )  |> 
  left_join(
    species_summary |> select(species_taxon_id, n_species), 
    by = "species_taxon_id", relationship = "many-to-one"
  ) |> 
  mutate(percentageOfSpecies = round(n_taxon_id / n_species * 100, 1)) |> 
  rename(
    subspecies = subsp,
    variety = var
  ) |> 
  select(-n_species) |> 
  rename(
    count = n_taxon_id,
    danishCommonName = common_name
  ) |> 
  select(-taxon_id) |> 
  group_by(species_taxon_id) %>%
  reframe(infraspecies = list((pick(everything()))))
  
# Counts per species per decade
species_decades <- df %>%
  mutate(decade = paste0(floor(planting_year / 10) * 10, "s")) %>%
  count(species_taxon_id, decade) %>%
  nest(decade = c(decade, n)) |> 
  mutate(decade = map(decade, ~setNames(as.list(.x$n), .x$decade)))


# Combine and convert
final <- species_summary %>%
  left_join(genus_summary) %>%
  left_join(species_districts) %>%
  left_join(species_decades) |> 
  left_join(species_infra) |> 
  left_join(species_names, by = "species_taxon_id", relationship = "one-to-one") |> 
  rename(
    count = n_species,
    speciesName = species_name,
    speciesDanishName = species_common_name,
    genusName = genus_name,
    genusDanishName = genus_common_name
  ) |> 
  select(species_taxon_id, speciesName, speciesDanishName, genusName, genusDanishName, everything(), -genus_id) |> 
  arrange(speciesName)
  
# Convert to named list (species as keys)
json_list <- final %>%
  select(-species_taxon_id) %>%
  pmap(function(...) list(...)) %>%   # each row → named list
  set_names(final$speciesName) 

final |> write_rds("2025/species_descriptions/species_data_2026.rds")
json_list |> write_json("2025/species_descriptions/species_data_2026.json", pretty = TRUE, auto_unbox = TRUE)
