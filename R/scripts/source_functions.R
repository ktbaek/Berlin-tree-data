# source functions
r_files <- list.files("R/functions", pattern = "\\.R$", full.names = TRUE)
invisible(lapply(r_files, source))