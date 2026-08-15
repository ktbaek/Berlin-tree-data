icon_df <- as_tibble(DBI::dbGetQuery(con, 
                                     "
SELECT
i.icon_id,
tdn.scientific_name_medium AS scientific_name,
CASE WHEN tdn.common_name IS NULL THEN tdn.scientific_name_medium
ELSE tdn.common_name
END AS common_name_de,
tdn.cultivar

FROM taxon_icons i 
JOIN taxon_display_names tdn USING (taxon_id)
WHERE icon_id IS NOT NULL
")) 

rows_to_named_list <- function(df) {
  row <- as.list(df[1, setdiff(names(df), "taxon_id")])
  
  # Helper: NA → NULL
  null_if_na <- \(x) if (length(x) == 1 && is.na(x)) NULL else x
  
  # Nest the *_da / *_en pairs into sub-objects
  nest_lang_pair <- function(row, base) {
    de <- null_if_na(row[[paste0(base, "_de")]])
    en <- null_if_na(row[[paste0(base, "_en")]])
    list(de = de, en = en)
  }
  
  lang_bases <- c("common_name")
  flat_cols  <- setdiff(names(row), paste0(rep(lang_bases, each = 2), c("_de", "_en")))
  
  out <- lapply(row[flat_cols], null_if_na)
  for (base in lang_bases) {
    out[[base]] <- nest_lang_pair(row, base)
  }
  
  out
}

split(icon_df, icon_df$icon_id) |> 
  lapply(rows_to_named_list) |> 
  write_json(
    "../website/src/assets/dataset/icon_lookup.json",
    pretty = TRUE,
    auto_unbox = TRUE,
    null = "null"
  )



