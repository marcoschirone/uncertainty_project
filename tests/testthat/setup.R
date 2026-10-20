suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(purrr)
  library(tibble)
  library(ggplot2)
})
root <- normalizePath(file.path("..", ".."))
for (f in list.files(file.path(root, "R"), "\\.R$", full.names = TRUE)) source(f)

reference_files <- list.files(file.path(root, c("data/reference", "data/corrections")),
                              "\\.csv$", full.names = TRUE)

write_export <- function(records) {
  path <- tempfile(fileext = ".txt")
  writeLines(c("FN Clarivate Analytics Web of Science", "VR 1.0", unlist(records), "EF"), path)
  path
}
