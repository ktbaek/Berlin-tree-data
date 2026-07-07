# Making map-ready version of the dataset ---------------------------------

# source functions
r_files <- list.files("R/functions", pattern = "\\.R$", full.names = TRUE)
invisible(lapply(r_files, source))
  
map_df <- as_tibble(DBI::dbGetQuery(con, "SELECT * FROM trees_for_map"))

# calculate radii
this_year <- as.integer(format(Sys.Date(), "%Y"))

radius_df <- map_df |> 
  select(planting_year) |> 
  filter(!is.na(planting_year)) |> 
  distinct() |> 
  arrange(planting_year) |> 
  mutate(radius = round(calc_radius(year = planting_year, current_year = this_year, r0 = 2.2, a0 = 25, k = 0.7), 2)) 

# add truncated uuid as id
trees_df <- map_df |> mutate(id = str_sub(gisid, start = -8, end = -1))
if (length(unique(map_df$gisid)) != length(unique(trees_df$id))) cli::cli_alert_warning("IDs not unique")
trees_df$gisid <- NULL

trees_df <- trees_df |> 
  arrange(desc(is.na(taxon_id)), planting_year, id) |> 
  rename(pyr = planting_year, tid = taxon_id) |> 
  mutate(lon = round(lon, 6), lat = round(lat, 6))

source("R/scripts/calculate_counts.R")

# prepare for PMTiles
taxon_df <- as_tibble(DBI::dbGetQuery(con, "SELECT * FROM taxon_lookup_for_map ORDER BY taxon_id")) |> 
  mutate(treetype = ifelse(treetype == 1, NA_integer_, treetype)) # remove ability to filter on Laubbäume bc 95% of trees

trees_for_tiles <- trees_df |>
  left_join(taxon_df, by = join_by("tid" == "taxon_id")) |>
  left_join(radius_df, by = join_by("pyr" == "planting_year")) |> 
  select(-c(tree_height, scientific_name, display_name, cultivar, common_name_de, genus_name, genus_common_name_de, species_common_name_de, icon_id)) |> 
  mutate(
    fillcolor = coalesce(fillcolor, "#56C667"),
    radius = coalesce(radius, 5.5),
    isOld = this_year - 100 >= pyr,
    isYoung = this_year - 5 <= pyr
  ) |> 
  mutate(
    draw_order = runif(n()),
    draw_order = as.integer(round(draw_order, 1) * 10)
  )
  

trees_for_tiles_sf <- sf::st_as_sf(trees_for_tiles, coords = c("lon", "lat"), crs = 4326)
st_write(trees_for_tiles_sf, "output/datasets/trees_resolved.geojson", driver = "GeoJSON", delete_dsn = TRUE)


