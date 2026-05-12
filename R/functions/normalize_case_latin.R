normalize_case_latin <- function(df, report = NULL) {
  
  before <- df$art_bot
  df <- df %>% mutate(
    art_bot = sub("(')(\\w)", "\\1\\U\\2", art_bot, perl = TRUE),
    art_bot = sub("^([A-Za-z])", "\\U\\1", art_bot, perl = TRUE)
  )
  after <- df$art_bot
  hits <- which(before != after)
  before <- before[hits]
  after <- after[hits]
  
  if (!is.null(report)) report$add("WRONG_CASE_LATIN", df$gisid[hits], "art_bot", before, after, message = "fix casing latin name")
  
  cli::cli_alert_success(paste0("WRONG_CASE_LATIN made ", length(hits), " changes."))
  
  df
  }