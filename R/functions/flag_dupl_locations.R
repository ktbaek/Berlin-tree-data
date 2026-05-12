flag_dupl_locations <- function(df, report = NULL) {
  
  df <- df %>%
    group_by(wkb_geometry) %>%
    mutate(
      dup_n = n(),
      dup_loc = dup_n > 1
    ) |> 
    ungroup() |> 
    select(-dup_n)
      
  
  if (!is.null(report)) {
    hits <- which(df$dup_loc)
    if (length(hits)) report$add("DUPLICATE_LOCATION", df$uuid[hits], "wkb_geometry", df$wkb_geometry[hits],  message = "duplicate location flag added")
  }
  cli::cli_alert_success(paste0("DUPLICATE_LOCATION flagged ", length(hits), " trees."))
  
  df
}