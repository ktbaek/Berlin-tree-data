# Cleaning and QC of Copenhagen Municipality's tree dataset ---------------
suppressWarnings({

# source functions
#rm(set_color_df) # during development 
r_files <- list.files("R/functions", pattern = "\\.R$", full.names = TRUE)
invisible(lapply(r_files, source))

#read raw data
street_trees_df <- read_csv("raw_data/2026/street_trees.csv")
park_trees_df <- read_csv("raw_data/2026/park_trees.csv")

trees_df <-
  bind_rows(
    street_trees_df |> mutate(dataset = "Street"),
    park_trees_df |> mutate(dataset = "Park")
  )

# load rules
dir <- "rules"
paths <- list.files(dir, pattern = "\\.csv$", full.names = TRUE)
rules <- set_names(paths, tools::file_path_sans_ext(basename(paths))) |>
  map(read_rules)

# make reporter
rep <- tt_make_reporter()

# Cleaning workflow
df <- trees_df |>
  normalize_year(upper_bound = 2026, report = rep) |> 
  # Spelling, casing and normalization of scientific names
  apply_regex_rules(rules = rules$markers, report = rep) |> # normalize hybrid markers, cultivar markers
  apply_regex_rules(rules = rules$latin_regex, report = rep) |> 
  apply_regex_rules(rules = rules$latin_regex_malus, report = rep) |> 
  normalize_case_latin(report = rep) |> 
  
  # whitespace QC
  mutate(across(where(is.character), str_squish)) |> 
  
  #flag trees with duplicate location 
  flag_dupl_locations(report = rep) |> 
  arrange(gisid)

# get report
changelog <- rep$get()
changelog |> write_csv("output/changelog/changelog.csv")

# summarize report
changelog_summary <- changelog |>
  group_by(code, message) |>
  summarize(n = n(), .groups = "drop") |>
  arrange(desc(n))  %T>%
  write_csv("output/changelog/changelog_summary.csv")

changelog_unique <- changelog |>
  group_by(code, value_from, value_to, message) |>
  mutate(n = n()) |>
  select(code, value_from, value_to, message, n) |>
  distinct() |> 
  arrange(code, message, value_from) %T>%
 write_csv("output/changelog/changelog_unique.csv")

cli::cli_alert_success(paste0(cli::col_cyan(nrow(changelog)), " total changes. ", cli::col_cyan(nrow(changelog_unique)), " total unique changes."))

# write cleaned data frame
 df |> write_csv('output/datasets/bln_trees_clean.csv')
 #df |> write_rds('output/datasets/bln_trees_clean.rds')
 })