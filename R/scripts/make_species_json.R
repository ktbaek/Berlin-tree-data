
# get data from db
df <- as_tibble(DBI::dbGetQuery(con, 
"
WITH trees AS (

SELECT
tfm.gisid,
t.dataset,
t.taxon_id,
t.planting_year,
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
tx.common_name_de,
tx.species_common_name_de,
tx.genus_name,
tx.genus_common_name_de,
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

species_names <- as_tibble(DBI::dbGetQuery(con, 
"
SELECT DISTINCT
species_taxon_id,
scientific_name

FROM taxon_lookup_for_map
WHERE species_taxon_id IS NOT NULL
"))

locations <- as_tibble(DBI::dbGetQuery(con, 
"
SELECT 
gisid,
lon,
lat

FROM trees_for_map
"))

west_berlin <- st_read("geodata/west_berlin.geojson", quiet = TRUE)

in_former_west <- locations %>%
  st_as_sf(coords = c("lon", "lat"), crs = 4326) %>%
  st_transform(st_crs(west_berlin)) %>%
  mutate(in_former_west = lengths(st_within(., west_berlin)) > 0) %>%
  st_drop_geometry()

df <- df |> left_join(in_former_west, by = "gisid")

total_count <- nrow(df)
total_known <- sum(!is.na(df$taxon_id))

# Summary per species
species_summary <- df %>%
  filter(!is.na(species_taxon_id)) |>
  group_by(species_taxon_id) %>%
  summarise(
    species_common_name_de = first(species_common_name_de),
    genus_name = first(genus_name),
    genus_common_name_de = first(genus_common_name_de),
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

# verify n_species = count in "species_count.json"
sc <- fromJSON("../website/src/assets/dataset/species_count.json") |> 
  enframe(name = "species_taxon_id", value = "count") |> 
  unnest(count) |> 
  mutate(species_taxon_id = as.integer(species_taxon_id))

# should return 0 rows
species_summary |> 
  left_join(sc, by = "species_taxon_id") |> 
  filter(count != n_species)

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
    expected = n_species * (n_district / total_count),
    z = round((n_district_species - expected) / sqrt(expected), 1),
    enrichment = round((n_district_species / n_species) / (n_district / total_count), 1),
    percentageOfSpecies = round(n_district_species / n_species * 100, 1)
  ) |> 
  # step 1: preliminary flag
  mutate(
    districtFlag = case_when(
      n_species < 50 & percentageOfSpecies > 80 ~ "unusual",
      n_species < 50                            ~ "none",
      z >= 4 & percentageOfSpecies >= 30         ~ "strong",
      z >= 4 & percentageOfSpecies >= 15         ~ "moderate",
      z <= -6 & percentageOfSpecies < 2 & expected >= 20 ~ "absent",
      TRUE                                       ~ "none"
    )
  ) |> 
  # step 2: determine if absent-candidates are isolated enough to keep
  mutate(
    z_lowest       = sort(z)[1],
    z_2nd_lowest   = sort(z)[2],
    gap_to_next    = z_2nd_lowest - z_lowest,
    n_very_negative = sum(z <= -10)
  ) |> 
  mutate(
    districtFlag = case_when(
      districtFlag == "absent" & z == z_lowest & gap_to_next >= 3 & n_very_negative <= 2 ~ "absent",
      districtFlag == "absent"                                                            ~ "none",
      TRUE                                                                                 ~ districtFlag
    )
  ) |> 
  select(-n_district, -n_species, -expected, -z_lowest, -z_2nd_lowest, -gap_to_next) |>
  rename(
    name = district_name,
    count = n_district_species
  ) |> 
  group_by(species_taxon_id) %>%
  reframe(districtStats = list(pick(everything())))

# Former East/West calculations
# during division
zone_totals <- df %>%
  filter(planting_year >= 1946, planting_year <= 1989, !is.na(in_former_west)) |> 
  count(in_former_west, name = "n_zone_total")

total_period <- sum(zone_totals$n_zone_total)

species_zone_counts <- df |> 
  filter(planting_year >= 1946, planting_year <= 1989, !is.na(in_former_west)) |> 
  group_by(species_taxon_id, scientific_name) |> 
  count(in_former_west) 

zone_stats <- species_zone_counts %>%
  group_by(species_taxon_id, scientific_name) %>%
  mutate(n_species = sum(n)) %>%
  ungroup() %>%
  left_join(zone_totals, by = "in_former_west") %>%
  mutate(
    expected            = n_species * (n_zone_total / total_period),
    z                   = round((n - expected) / sqrt(expected), 1),
    enrichment          = round((n / n_species) / (n_zone_total / total_period), 1),
    percentageOfSpecies = round(n / n_species * 100, 1)
  ) %>%
  select(-n_zone_total)

# after reunification
zone_totals_post <- df %>%
  filter(planting_year < 1940, !is.na(in_former_west)) %>%
  count(in_former_west, name = "n_zone_total")

total_post <- sum(zone_totals_post$n_zone_total)

species_zone_counts_post <- df |> 
  filter(planting_year < 1940, !is.na(in_former_west)) |> 
  group_by(species_taxon_id, scientific_name) |> 
  count(in_former_west) 

zone_stats_post <- species_zone_counts_post %>% 
  group_by(species_taxon_id, scientific_name) %>%
  mutate(n_species = sum(n)) %>%
  ungroup() %>%
  left_join(zone_totals_post, by = "in_former_west") %>%
  mutate(
    expected            = n_species * (n_zone_total / total_post),
    z                   = round((n - expected) / sqrt(expected), 1),
    enrichment          = round((n / n_species) / (n_zone_total / total_post), 1),
    percentageOfSpecies = round(n / n_species * 100, 1)
  ) %>%
  select(-n_zone_total)

# is there convergence after reunificiation?
convergence_check <- zone_stats %>%
  select(species_taxon_id, scientific_name, in_former_west, enrichment_period = enrichment) %>%
  inner_join(
    zone_stats_post |>  select(species_taxon_id, in_former_west, enrichment_post = enrichment),
    by = c("species_taxon_id", "in_former_west")
  ) %>%
  mutate(enrichment_diff = enrichment_post - enrichment_period)
 
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
    count = n_taxon_id#,
    #germanCommonName = common_name
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
    speciesName = scientific_name,
    speciesGermanName = species_common_name_de,
    genusName = genus_name,
    genusGermanName = genus_common_name_de
  ) |> 
  select(species_taxon_id, speciesName, speciesGermanName, genusName, genusGermanName, everything(), -genus_taxon_id) |> 
  arrange(speciesName)
  
# Convert to named list (species as keys)
json_list <- final %>%
  select(-species_taxon_id) %>%
  pmap(function(...) list(...)) %>%   # each row → named list
  set_names(final$speciesName) 

json_list |> write_json("species_descriptions/species_data_2026.json", pretty = TRUE, auto_unbox = TRUE)
