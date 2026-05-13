flag_dupl_locations <- function(df, report = NULL) {
  
  df <- df %>%
    group_by(geom) %>%
    mutate(
      dup_n = n(),
      dup_loc = dup_n > 1
    ) |> 
    ungroup() |> 
    select(-dup_n)
      
  
  if (!is.null(report)) {
    hits <- which(df$dup_loc)
    if (length(hits)) report$add("DUPLICATE_LOCATION", df$gisid[hits], "geom", df$geom[hits],  message = "duplicate location flag added")
  }
  cli::cli_alert_success(paste0("DUPLICATE_LOCATION flagged ", length(hits), " trees."))
  
  df
}