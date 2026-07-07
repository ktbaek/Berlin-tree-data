normalize_year <- function(df, lower_bound = 1000, upper_bound, report = NULL) {
  
  hits <- which(!is.na(df$pflanzjahr) & !df$pflanzjahr %in% c(lower_bound:upper_bound))
  if (!length(hits)) return(df)
  
  before <- df$pflanzjahr[hits]
  df$pflanzjahr[hits] <- NA_integer_
  after  <- df$pflanzjahr[hits]  # now NA
  
  if (!is.null(report)) report$add("YEAR_RANGE", df$gisid[hits], "pflanzjahr", before, after, message = "year outside allowed range")
  
  cli::cli_alert_success(paste0("YEAR_RANGE made ", length(hits), " changes."))
  
  df$pflanzjahr <- as.integer(df$pflanzjahr)
  
  df
}