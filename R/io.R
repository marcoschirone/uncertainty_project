# Input resolution, output writers and the run log.

#' Locate an input export
#'
#' Licensed Web of Science exports in `data/private/` take precedence over the
#' synthetic demonstration files in `data/raw/`.
input_file <- function(name, root = ".") {
  private <- file.path(root, "data", "private", name)
  if (file.exists(private)) private else file.path(root, "data", "raw", name)
}

uses_licensed_data <- function(path) {
  grepl("(^|/)data/private/", path)
}

read_reference_csv <- function(path) {
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
                  encoding = "UTF-8", na.strings = c("", "NA"))
}

#' Mark a table so that its row names are written
with_row_names <- function(x) {
  attr(x, "write_row_names") <- TRUE
  x
}

#' Write a named list of tables as CSV files and return their paths
write_tables <- function(tables, dir) {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  tables <- tables[!vapply(tables, is.null, logical(1))]
  if (!length(tables)) return(character(0))
  paths <- file.path(dir, paste0(names(tables), ".csv"))
  for (i in seq_along(tables)) {
    x <- tables[[i]]
    row_names <- is.matrix(x) || isTRUE(attr(x, "write_row_names"))
    if (!is.matrix(x)) x <- as.data.frame(x)
    utils::write.csv(x, paths[i], row.names = row_names, fileEncoding = "UTF-8")
  }
  paths
}

#' Save a named list of figures and return their paths
#'
#' Each element is a list with `plot`, `width` and `height` (inches).
write_figures <- function(figures, dir, dpi = 300) {
  if (!length(figures)) return(character(0))
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  paths <- file.path(dir, paste0(names(figures), ".png"))
  for (i in seq_along(figures)) {
    f <- figures[[i]]
    ggplot2::ggsave(paths[i], f$plot, width = f$width, height = f$height, dpi = dpi)
  }
  paths
}

figure <- function(plot, width, height) {
  list(plot = plot, width = width, height = height)
}

#' Write the run log: corpus totals and the R session
write_run_log <- function(path, wos, corpus, base, coupling, settings) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  out <- c(
    "Bibliographic coupling to the Uncertainty Project intellectual base",
    paste("Date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
    paste("Input:", if (settings$licensed) "licensed Web of Science exports (data/private)"
                    else "synthetic demonstration data (data/raw)"),
    "",
    sprintf("UP papers: %d | Citing (raw): %d | Citing (corrected): %d",
            nrow(wos$parts_records), nrow(wos$citing_records), nrow(coupling$coupling)),
    sprintf("Foundations: %d | High overlap: %d | No overlap: %d",
            nrow(base$foundations),
            sum(coupling$coupling$n_shared >= settings$heir_threshold),
            sum(coupling$coupling$n_shared == 0)),
    "",
    "Record correction summary:",
    utils::capture.output(print(as.data.frame(corpus$record_summary))),
    "",
    utils::capture.output(print(utils::sessionInfo()))
  )
  writeLines(out, path, useBytes = TRUE)
  path
}

#' Refresh results/ from a licensed run
#'
#' Copies the derived tables and figures into results/. Web of Science record
#' content is withheld: the full citing records, and the author addresses in
#' the author-overlap audit table. Runs only on the licensed data, so the
#' synthetic demonstration never overwrites the published results.
publish_results <- function(settings, table_files, figure_files, log_file, facts, dir = "results") {
  if (!settings$licensed) return(character(0))
  withheld <- c("corrected_citing_records.csv")
  copy_into <- function(files, from, to) {
    files <- files[!basename(files) %in% withheld]
    dest <- file.path(to, substring(files, nchar(from) + 2))
    for (d in unique(dirname(dest))) dir.create(d, recursive = TRUE, showWarnings = FALSE)
    file.copy(files, dest, overwrite = TRUE)
    dest
  }
  tables <- copy_into(table_files, file.path("output", "tables"), file.path(dir, "tables"))
  audit <- tables[basename(tables) == "author_overlap_records.csv"]
  if (length(audit)) {
    x <- utils::read.csv(audit, check.names = FALSE, encoding = "UTF-8")
    x$affiliation <- NULL
    utils::write.csv(x, audit, row.names = FALSE, fileEncoding = "UTF-8")
  }
  figures <- copy_into(figure_files, file.path("output", "figures"), file.path(dir, "figures"))
  logs <- file.path(dir, "logs", "session_info.txt")
  dir.create(dirname(logs), recursive = TRUE, showWarnings = FALSE)
  file.copy(log_file, logs, overwrite = TRUE)
  numbers <- write_tables(list(reported_numbers = facts), dir)
  c(tables, figures, logs, numbers)
}
