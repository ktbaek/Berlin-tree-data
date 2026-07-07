# source functions
r_files <- list.files("R/functions", pattern = "\\.R$", full.names = TRUE)
invisible(lapply(r_files, source))

# taxon level lookup
taxon_df <- as_tibble(DBI::dbGetQuery(con, "SELECT * FROM taxon_lookup_for_map ORDER BY taxon_id")) |> 
  mutate(treetype = ifelse(treetype == 1, NA_integer_, treetype)) # remove ability to filter on Laubbäume bc 95% of trees

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
  
  lang_bases <- c("common_name", "genus_common_name", "species_common_name")
  flat_cols  <- setdiff(names(row), paste0(rep(lang_bases, each = 2), c("_de", "_en")))
  
  out <- lapply(row[flat_cols], null_if_na)
  for (base in lang_bases) {
    out[[base]] <- nest_lang_pair(row, base)
  }
  
  out
}


split(taxon_df, taxon_df$taxon_id) |> 
  lapply(rows_to_named_list) |> 
  write_json(
    "../website/src/assets/dataset/taxon_lookup.json",
    pretty = TRUE,
    auto_unbox = TRUE,
    null = "null"
  )
