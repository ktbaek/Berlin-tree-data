expand_taxonomy <- function(row) {
  
  row <- as.list(row)
  
  out <- list()
  i <- 1
  
  # -----------------------
  # GENUS
  # -----------------------
  out[[i]] <- tibble(
    genus = row$genus,
    species = NA_character_,
    subsp = NA_character_,
    var = NA_character_,
    form = NA_character_,
    cultivar = NA_character_,
    selection = NA_character_,
    is_hybrid = NA,
    rank = "genus"
  )
  i <- i + 1
  
  has_species <- !is.null(row$species) &&
    !is.na(row$species) &&
    row$species != ""
  
  is_hybrid <- isTRUE(row$is_hybrid)
  
  # -----------------------
  # SPECIES LEVEL
  # -----------------------
  if (has_species || is_hybrid) {
    
    species_value <- if (has_species) row$species else NA_character_
    
    out[[i]] <- tibble(
      genus = row$genus,
      species = species_value,
      subsp = NA_character_,
      var = NA_character_,
      form = NA_character_,
      cultivar = NA_character_,
      selection = NA_character_,
      
      # IMPORTANT FIX:
      # species node explicitly carries TRUE/FALSE OR TRUE for hybrid-only species
      is_hybrid = if (has_species) is_hybrid else TRUE,
      
      rank = "species"
    )
    
    i <- i + 1
  }
  
  # -----------------------
  # LOWER RANKS
  # -----------------------
  ranks <- c(
    subsp = "subsp.",
    var = "var.",
    form = "f.",
    cultivar = "cultivar",
    selection = "sel."
  )
  
  current <- list(
    genus = row$genus,
    species = if (has_species) row$species else NA_character_,
    subsp = NA_character_,
    var = NA_character_,
    form = NA_character_,
    cultivar = NA_character_,
    selection = NA_character_
  )
  
  for (col in names(ranks)) {
    
    value <- row[[col]]
    
    if (!is.null(value) && !is.na(value) && value != "") {
      
      current[[col]] <- value
      
      out[[i]] <- tibble(
        genus = current$genus,
        species = current$species,
        subsp = current$subsp,
        var = current$var,
        form = current$form,
        cultivar = current$cultivar,
        selection = current$selection,
        
        # IMPORTANT FIX:
        is_hybrid = is_hybrid,
        
        rank = ranks[[col]]
      )
      
      i <- i + 1
    }
  }
  
  bind_rows(out)
}