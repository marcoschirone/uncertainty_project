required_packages <- c(
  "bibliometrix",
  "dplyr",
  "stringr",
  "tidyr",
  "purrr",
  "ggplot2"
)

missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]

if (length(missing_packages) > 0) {
  stop(
    "Missing required R packages: ",
    paste(missing_packages, collapse = ", "),
    "\nInstall them before running the project.",
    call. = FALSE
  )
}

library(bibliometrix)
library(dplyr)
library(stringr)
library(tidyr)
library(purrr)
library(ggplot2)

theme_set(
  theme_minimal(base_size = 11) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold", size = 12),
      plot.subtitle = element_text(colour = "grey40", size = 10)
    )
)
