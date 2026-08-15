# source functions
r_files <- list.files("R/functions", pattern = "\\.R$", full.names = TRUE)
invisible(lapply(r_files, source))

# load rules
dir <- "rules"
paths <- list.files(dir, pattern = "\\.csv$", full.names = TRUE)
rules <- set_names(paths, tools::file_path_sans_ext(basename(paths))) |>
  map(read_rules)

# read dataset
clean_df <- read_csv('output/datasets/bln_trees_clean.csv')

# check that gattung col and art_bot name correspond, zero rows expected
# clean_df |> filter(word(art_bot, 1) != gattung)

# harmonize cleaned dataset
split_taxon_df <- clean_df |> 
  split_taxon_columns() |> 
  mutate(
    is_hybrid = case_when(
      !is.na(genus) & is.na(species) & !is_hybrid ~ NA,
      TRUE ~ is_hybrid
    )
  )

harmonized_df <- split_taxon_df |> 
  rename(
    tree_type = art_gruppe,
    planting_year = pflanzjahr,
    trunk_circ = stammumfg,
    tree_height = baumhoehe,
    district_name = bezirk,
    place_name = namenr,
    is_duplicate_location = dup_loc
  ) 

# generate trees table
trees_df <- harmonized_df |>
  mutate(updated_at = today()) |> 
  select(
    updated_at,
    dataset,
    gisid, 
    genus, 
    species, 
    is_hybrid, 
    subsp,
    var,
    form, 
    selection, 
    cultivar, 
    planting_year, 
    tree_type, 
    trunk_circ, 
    tree_height, 
    place_name, 
    district_name, 
    lon,
    lat,
    is_duplicate_location, 
    art_dtsch, 
    gattung_deutsch
    ) 
  
trees_df |> write_csv('output/tables/trees_2026.csv', na = "")

clean_df |> 
  select(gisid, standortnr) |> 
  rename(tree_number = standortnr) |> 
  #mutate(tree_number = str_remove(tree_number, "^0+")) |> 
  write_csv('output/tables/tree_numbers.csv', na = "")

# generate family table
family_df <- rules$taxonomy |> 
  select(family, order) |> 
  rename(
    family_name = family,
    order_name = order
  ) |> 
  distinct() |> 
  arrange(family_name)

family_df |> write_csv('output/tables/families.csv', na = "")

# generate order table
order_df <- rules$taxonomy |> 
  select(order) |> 
  rename(
    order_name = order
  ) |> 
  distinct() |> 
  arrange(order_name)

order_df |> write_csv('output/tables/orders.csv', na = "")

# generate taxa table
taxa_raw <- split_taxon_df |>
  filter(!is.na(genus)) |> 
  select(
         genus, 
         species, 
         is_hybrid, 
         var, 
         subsp, 
         form, 
         selection, 
         cultivar
         ) |> 
  distinct() 

taxa_complete <- split(taxa_raw, seq_len(nrow(taxa_raw))) |>
  purrr::map_dfr(expand_taxonomy) |>
  distinct() |> 
  arrange(genus) |> 
  relocate(is_hybrid, .after = species) |> 
  left_join(rules$taxonomy |> select(-order), by = "genus") |> 
  relocate(family, .before = genus) |> 
  rename(taxon_level = rank)

taxa_complete |> write_csv('output/tables/taxa.csv', na = "")


# generate districts table
districts_df <- harmonized_df |> 
  select(district_name) |> 
  distinct() |> 
  filter(!is.na(district_name)) |> 
  arrange(district_name)

districts_df |> write_csv('output/tables/districts.csv', na = "")

# generate places table
places_df <- harmonized_df |> 
  filter(!is.na(place_name) & !is.na(district_name)) |> 
  select(place_name, district_name) |> 
  distinct() |> 
  bind_rows(districts_df |> mutate(place_name = NA_character_))

places_df |> write_csv('output/tables/places.csv', na = "")

# generate common names table, needs further work, but for now this is ok
common <- clean_df |> select(art_bot, art_dtsch) |> distinct()

common_by_taxon <- common |> 
  filter(!is.na(art_bot)) |> 
  split_taxon_columns() |> 
  mutate(is_hybrid = ifelse(!is_hybrid & is.na(species), NA, is_hybrid)) |> 
  rename(common_name = art_dtsch) |> 
  select(genus, species, is_hybrid, subsp, var, form, selection, cultivar, common_name) |> 
  separate_rows(common_name, sep = ",\\s*") |> 
  mutate(common_name = str_squish(common_name)) |> 
  filter(!is.na(common_name))

common_by_taxon |> write_csv('output/tables/taxon_common_names.csv', na = "")

icons_df <- read_csv('output/tables/icons_cph.csv')

icons_df |> 
  rename(species = species_epithet) |> 
  pivot_wider(names_from = infraspecies_type, values_from = infraspecies_name) |> 
  select(-(`NA`)) |>
  mutate(
    subsp = NA_character_,
    var = NA_character_,
    form = NA_character_,
    selection = NA_character_
  ) |> 
  select(genus, species, is_hybrid, subsp, var, form, selection, cultivar, icon_id, allow_fallback) |> 
  write_csv('output/tables/icons.csv', na = "")
  