split_taxon_columns <- function(df) {
  
  df <- df %>%
    mutate(
      
      # cultivar in quotes
      cultivar = str_match(
        art_bot,
        "(?<=\\s)['\"](.+)['\"]\\s*$"
      )[, 2],
      
      # hybrid marker
      is_hybrid = str_detect(art_bot, "\\bhybr\\."),
      
      # remove cultivar before parsing
      taxon_base = 
        str_remove(art_bot, "\\s*['\"].+['\"]\\s*$") |> 
        str_replace_all("hybr\\.", "") |> 
        str_squish(),
      
      # genus = first token
      genus = word(taxon_base, 1),
      
      # species: first lowercase epithet, optionally skipping hybr.
      species = str_match(
        taxon_base,
        "^[A-Z][A-Za-z.-]+\\s+(?:hybr\\.\\s+)?([a-z][a-z-]*)"
      )[, 2],
      
      # explicit infra ranks
      subsp = str_match(
        taxon_base,
        "\\b(?:subsp\\.|ssp\\.)\\s+([a-z-]+)"
      )[, 2],
      
      var = str_match(
        taxon_base,
        "\\bvar\\.\\s+([a-z-]+)"
      )[, 2],
      
      form = str_match(
        taxon_base,
        "\\bf\\.\\s+([a-z-]+)"
      )[, 2],
      
      selection = str_match(
        taxon_base,
        "\\bsel\\.\\s+([A-Za-z0-9_-]+)"
      )[, 2]
      
    ) %>%
    
    mutate(
      # "Genus sp." → no species epithet
      species = if_else(
        str_detect(taxon_base, "\\bsp\\.?\\s*$"),
        NA_character_,
        species
      )
    ) %>%
    
    select(-taxon_base)
  
  cli::cli_alert_success("Taxon columns were split")
  df
}