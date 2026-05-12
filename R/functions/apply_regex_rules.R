apply_regex_rules <- function(df, rules, report = NULL) {
  if (is.null(rules) || nrow(rules) == 0) return(df)
  
  ruleset <- attr(rules, "ruleset")
  
  k <- 0L # counter
  
  for (i in seq_len(nrow(rules))) {
    col <- rules$column[i]
    pat <- rules$pattern[i]
    repl <- rules$replacement[i]
    if (!col %in% names(df)) next
    before <- df[[col]]
    df[[col]] <- stringr::str_replace_all(before, stringr::regex(pat), repl)
    after <- df[[col]]
    
    if (!is.null(report)) {
      msg <-  rules$note[i]
      hits <- which(!is.na(before) & before != after)
      k <- k + length(hits)
      
      if (length(hits)) report$add("APPLIED_REGEX_RULE", df$gisid[hits], col, before[hits], after[hits], ruleset = ruleset, message = msg)
    }
  }
  cli::cli_alert_success(paste0("APPLIED_REGEX_RULE using ruleset ", cli::col_magenta(ruleset), " made ", k, " changes."))
  
  df
}