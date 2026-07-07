# function to calculate radius of marker dependent on plant year
calc_radius <- function(year, current_year, r0, a0 = 25, k = 1) {
  yr  <- coalesce(year, current_year - a0)
  age <- pmax((current_year + 1) - yr, 1)
  r0 + k * log2(age)          
}