# Cleaning and QC of Copenhagen Municipality's tree dataset ---------------
suppressWarnings({
# set constants
dataset_year = 2026L

# source functions
rm(set_color_df) # during development 
r_files <- list.files("../../treemap_cph/tidytrees/2025/R/functions", pattern = "\\.R$", full.names = TRUE)
invisible(lapply(r_files, source))

# read raw data
street_trees_df <- read_csv("raw_dataset/2026/street_trees.csv")

# load rules
dir <- "2025/rules"
paths <- list.files(dir, pattern = "\\.csv$", full.names = TRUE)
rules <- set_names(paths, tools::file_path_sans_ext(basename(paths))) |>
  map(read_rules)

# make reporter
rep <- tt_make_reporter()

# Cleaning workflow
df <- trees_df |>
  normalize_year(upper_bound = dataset_year, report = rep) |>
  
  # Spelling, casing and normalization of scientific names
  apply_regex_rules(rules = rules$markers, report = rep) |> # normalize hybrid markers, cultivar markers
  normalize_case_latin(report = rep) |> 
  apply_regex_rules(rules = rules$latin_regex, report = rep) |> 
  apply_regex_rules(rules = rules$latin_regex_malus, report = rep) |> 
  
  # whitespace QC
  mutate(across(where(is.character), str_squish)) |> 
  
  # flag trees with duplicate location
  flag_dupl_locations(report = rep) |> 
  arrange(id)

# get report
changelog <- rep$get()
changelog |> write_csv("2025/output/changelog/changelog.csv")

# summarize report
changelog_summary <- changelog |>
  group_by(code, message) |>
  summarize(n = n(), .groups = "drop") |>
  arrange(desc(n)) %T>%
  write_csv("2025/output/changelog/changelog_summary.csv")

changelog_unique <- changelog |>
  group_by(code, value_from, value_to, message) |>
  mutate(n = n()) |>
  select(code, value_from, value_to, message, n) |>
  distinct() |> 
  arrange(code, message, value_from) %T>%
  write_csv("2025/output/changelog/changelog_unique.csv")

cli::cli_alert_success(paste0(cli::col_cyan(nrow(changelog)), " total changes. ", cli::col_cyan(nrow(changelog_unique)), " total unique changes."))

# write cleaned data frame
 df |> write_csv('2025/output/datasets/kk_trees_clean.csv')
 df |> write_rds('2025/output/datasets/kk_trees_clean.rds')
 df |> write_json('2025/output/datasets/kk_trees_clean.json', digits = 6, pretty = TRUE)
 })