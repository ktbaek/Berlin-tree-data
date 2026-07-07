
taxonomy <- as_tibble(DBI::dbGetQuery(con, 
"SELECT
  tx.taxon_id,
  r.genus_taxon_id,
  r.species_taxon_id,
  tdn.scientific_name_short as scientific_name,
  r.genus as genus_name,
  f.family_name,
  o.order_name

  from taxa tx
  
LEFT JOIN taxon_resolver r
  ON r.taxon_id = tx.taxon_id

LEFT JOIN taxon_display_names tdn
  ON tdn.taxon_id = tx.taxon_id

LEFT JOIN families f
  ON f.family_id = tx.family_id

LEFT JOIN orders o
  ON o.order_id = f.order_id
"))

common_names <- as_tibble(DBI::dbGetQuery(con, 
"SELECT
  r.species_taxon_id,
  c.common_name

  from taxon_resolver r

LEFT JOIN taxon_primary_common_names c
  ON c.taxon_id = r.taxon_id
  
LEFT JOIN taxa tx
  ON tx.taxon_id = r.taxon_id
WHERE tx.taxon_level = 'species'
"))

# Create the base color data
color_scheme <- viridisLite::viridis(535, direction = -1, begin = 0.27, end = 0.95) 

okhex_df <- as_tibble(farver::decode_colour(color_scheme, to = "oklch")) |> 
  mutate(
    hex = color_scheme,
    number = row_number()
  )

# Define sorting order
sorting_cols <- c("order_name", "family_name", "genus_name", "sp_last", "scientific_name")

custom_orders_first <- list(
  order_name = c("Sapindales", "Fagales"),
  genus_name = c("Fagus")
)

custom_orders_last <- list(
  order_name = c("Fabales", 
            "Malvales", 
            "Aquifoliales", 
            "Buxales", 
            "Ericales", 
            "Cupressales", 
            "Pinales"),
  genus_name = c("Quercus")
)

taxo_df <- taxonomy |> 
  select(genus_taxon_id, species_taxon_id, order_name, family_name, genus_name, scientific_name) |> 
  distinct() |> 
  mutate(
    across(all_of(names(custom_orders_first)),
    ~forcats::fct_relevel(.x, custom_orders_first[[cur_column()]], after = 0)),
    across(all_of(names(custom_orders_last)),
           ~forcats::fct_relevel(.x, custom_orders_last[[cur_column()]], after = Inf)),
    sp_last = is.na(species_taxon_id)
    ) |>
  arrange(across(all_of(sorting_cols))) |>
  select(-sp_last) |> 
  mutate(seq = row_number())

# add colors to sorted species dataframe
taxo_color_df <- taxo_df |> 
  left_join(okhex_df, by = c("seq" = "number"), relationship = "one-to-one") 

species_colors_df <- taxonomy |> 
  select(taxon_id, genus_taxon_id, species_taxon_id) |> 
  left_join(taxo_color_df, by = c("genus_taxon_id", "species_taxon_id")) |> 
  select(taxon_id, hex) |> 
  rename(fillcolor = hex)

species_colors_df |> write_csv('output/tables/colors.csv', na = "")
cli::cli_alert_success("Color scales calculated")


# Convert color-taxonomy dataframe to tree
taxo_tree_df <- taxo_color_df |>
  filter(!is.na(species_taxon_id)) |> 
  left_join(common_names, by = join_by("species_taxon_id")) |> 
  rename(species = scientific_name,
         value = hex) |>
  rename_with(str_remove, pattern = "_name") |> 
  select(order, family, genus, species, common, value) |> 
  mutate(
    common = case_when(
      is.na(common) ~ NA_character_,
      TRUE ~ paste0("(", common, ")")
    )
  ) |> 
  unite("species", species:common, sep = " ", na.rm = TRUE, remove = FALSE)

taxo_tree_df$pathString <- paste("trees",
                                 taxo_tree_df$order,
                                 taxo_tree_df$family,
                                 taxo_tree_df$genus,
                                 taxo_tree_df$species,
                                sep = "/")

taxo_tree <- taxo_tree_df |>
  select(pathString, value) |>
  data.tree::as.Node()

# Convert to list format
taxo_tree_list <- data.tree::ToListExplicit(taxo_tree, unname = TRUE,
                            nameName = "name",
                            childrenName = "children")

# Write JSON
write(toJSON(taxo_tree_list, pretty = TRUE, auto_unbox = TRUE), '../website/src/assets/dataset/taxonomy.json')

cli::cli_alert_success("Taxonomy JSON generated")
