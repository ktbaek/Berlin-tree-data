read_rules <- function(path, sort_col = "priority") {
  df <- read_delim(path, delim = NULL, trim_ws = FALSE, show_col_types = FALSE, col_types = cols(.default = "c"))
  if ("priority" %in% names(df)) df$priority <- as.integer(df$priority)
  nm <- tools::file_path_sans_ext(basename(path))
  attr(df, "ruleset") <- nm
  if (sort_col %in% names(df)) df <- arrange(df, desc(.data[[sort_col]]))
  
  df
}