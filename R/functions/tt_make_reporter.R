tt_make_reporter <- function() {
  store <- new.env(parent = emptyenv())
  store$issues <- tibble::tibble(
    uuid = character(), code = character(), column = character(),
    value_from =  list(), value_to =  list(), ruleset = character(), message = character()
  )
  add <- function(code, uuid, column, value_from = NULL, value_to = NULL, ruleset = NA_character_, message = NA_character_, severity = NA_character_) {
    n <- length(uuid)
    if (!n) return(invisible(NULL))
    
    vf <- if (is.null(value_from)) rep(list(NA), n) else as.list(value_from)
    vt <- if (is.null(value_to))   rep(list(NA), n) else as.list(value_to)
    
    store$issues <- dplyr::bind_rows(
      store$issues,
      tibble::tibble(uuid = uuid, code = code, column = column,
                     value_from = vf, value_to = vt, ruleset = ruleset, message = message, severity = severity)
    )
    invisible(NULL)
  }
  
  get <- function(pretty = TRUE) {
    if (!pretty) return(store$issues)
    store$issues %>%
      dplyr::mutate(
        value_from = vapply(value_from, function(x) if (length(x) == 0 || is.na(x)) NA_character_ else as.character(x), character(1)),
        value_to   = vapply(value_to,   function(x) if (length(x) == 0 || is.na(x)) NA_character_ else as.character(x), character(1))
      )
  }
  list(add = add, get = get)
}