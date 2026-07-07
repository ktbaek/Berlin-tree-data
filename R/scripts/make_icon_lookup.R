icon_df <- as_tibble(DBI::dbGetQuery(con, 
                                     "
SELECT
i.icon_id,
tdn.scientific_name_medium AS scientific_name,
CASE WHEN tdn.display_common_name IS NULL THEN tdn.scientific_name_medium
ELSE tdn.display_common_name
END AS common_name,
tdn.cultivar

FROM taxon_icons i 
JOIN taxon_display_names tdn USING (taxon_id)
WHERE icon_id IS NOT NULL
")) 

rows_to_named_list <- function(df) {
  row <- as.list(df[1, setdiff(names(df), "icon_id")])
  # Convert any NA to NULL so jsonlite writes null not "NA"
  lapply(row, \(x) if (length(x) == 1 && is.na(x)) NULL else x)
}

split(icon_df, icon_df$icon_id) |> 
  lapply(rows_to_named_list) |> 
  write_json(
    "../website/src/assets/dataset/icon_lookup.json",
    pretty = TRUE,
    auto_unbox = TRUE,
    null = "null"
  )

