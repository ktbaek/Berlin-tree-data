normalize_case_latin <- function(df, report = NULL) {
  
  before <- df$art_bot
  df <- df %>% mutate(
    art_bot = tolower(art_bot),
    #art_bot = sub("(')(\\w)", "\\1\\U\\2", art_bot, perl = TRUE),
    art_bot = str_replace_all(art_bot, "[`´]", "'"),
    art_bot = str_replace_all(
      art_bot,
      "'([^,;]+)",
      \(x) paste0("'", str_to_title(sub("^'", "", x)))
    ),
    art_bot = sub("^([a-z])", "\\U\\1", art_bot, perl = TRUE),
    art_bot = sub("(?<!')\\b(Von|Van)\\b", "\\L\\1", art_bot, perl = TRUE)
  )
  after <- df$art_bot
  hits <- which(before != after)
  before <- before[hits]
  after <- after[hits]
  
  if (!is.null(report)) report$add("WRONG_CASE_LATIN", df$gisid[hits], "art_bot", before, after, message = "fix casing latin name")
  
  cli::cli_alert_success(paste0("WRONG_CASE_LATIN made ", length(hits), " changes."))
  
  df
  }