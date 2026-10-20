# Reading Web of Science plain-text exports and normalising cited references.

#' Read a WoS plain-text export into a record table
#'
#' Uses bibliometrix::convert2df(), which upper-cases the fields and splits
#' multi-valued tags with ";". Its console output is suppressed.
read_wos_records <- function(path) {
  utils::capture.output(
    m <- suppressWarnings(suppressMessages(
      bibliometrix::convert2df(path, dbsource = "wos", format = "plaintext")
    )),
    file = nullfile()
  )
  m <- as.data.frame(m)
  class(m) <- "data.frame"
  m
}

#' Extract the cited-reference (CR) field of every record
#'
#' Returns one row per cited reference with the record's accession number.
#' A record contributes only when it has a UT and at least one CR line, and
#' only once its ER (end of record) line has been read.
parse_wos_cr <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  if (length(lines) > 0 && startsWith(lines[1], "﻿")) {
    lines[1] <- substring(lines[1], 2)
  }
  raw <- trimws(lines, which = "right")

  is_end <- raw == "ER"
  is_tag <- nchar(raw) >= 3 & grepl("^[A-Z]{2} ", raw)
  record <- cumsum(is_end) - is_end

  tag <- ifelse(is_tag, substr(raw, 1, 2), NA_character_)
  tag[is_end] <- "ER"
  tag <- stats::ave(tag, record, FUN = fill_down)

  value <- ifelse(is_tag, trimws(substr(raw, 4, nchar(raw))), NA_character_)
  is_cr <- (is_tag & tag == "CR") |
    (!is_tag & !is_end & startsWith(raw, "   ") & !is.na(tag) & tag == "CR")
  value[is_cr & !is_tag] <- trimws(raw[is_cr & !is_tag])

  ut_rows <- which(is_tag & tag == "UT")
  ut_of_record <- tapply(value[ut_rows], record[ut_rows], function(x) x[length(x)])
  closed <- unique(record[is_end])

  keep <- is_cr & record %in% closed & as.character(record) %in% names(ut_of_record)
  data.frame(
    UT = unname(ut_of_record[as.character(record[keep])]),
    CR = value[keep],
    stringsAsFactors = FALSE
  )
}

fill_down <- function(x) {
  idx <- cumsum(!is.na(x))
  out <- rep(NA_character_, length(x))
  out[idx > 0] <- x[!is.na(x)][idx[idx > 0]]
  out
}

#' Normalise a cited reference to an "AUTHOR, YEAR, SOURCE" key
#'
#' The key is built from the first three comma-separated fields; references
#' with fewer fields fall back to the first field alone.
normalize_ref <- function(cr) {
  fields <- stringr::str_split(cr, ",\\s*")
  key <- vapply(fields, function(f) {
    if (length(f) >= 3) paste(f[1:3], collapse = ", ") else f[1]
  }, character(1))
  toupper(stringr::str_squish(key))
}

apply_merges <- function(keys, merge_rules) {
  idx <- match(keys, merge_rules$from)
  ifelse(is.na(idx), keys, merge_rules$to[idx])
}

add_ref_keys <- function(cr, merge_rules) {
  cr$ref_key <- apply_merges(normalize_ref(cr$CR), merge_rules)
  cr
}

is_generic <- function(key) {
  startsWith(key, "[ANONYMOUS]") | startsWith(key, "ANONYMOUS,") | startsWith(key, "*")
}

#' A key without a publication year cannot match any citing reference
#'
#' This happens for "in press" citations such as "SPINK A, IN PRESS
#' INFORMATION", which normalise to the author name alone.
is_unresolvable <- function(key) {
  !grepl("(^|[^0-9])(1[6-9]|20)[0-9]{2}([^0-9]|$)", key)
}

#' Publication year of a normalised reference key, NA when absent
ref_year <- function(key) {
  suppressWarnings(as.integer(
    stringr::str_match(key, ",\\s*((1[6-9]|20)[0-9]{2})\\s*,")[, 2]
  ))
}

#' Read both exports and restrict the citing set to Part citers
#'
#' The citing export may cover more project documents than the five Parts;
#' only records citing at least one Part by DOI are kept.
read_wos <- function(parts_file, citing_file, ref) {
  parts_records <- read_wos_records(parts_file)
  parts_records <- parts_records[parts_records$UT %in% ref$parts$UT, , drop = FALSE]
  if (nrow(parts_records) != nrow(ref$parts)) {
    stop("Expected ", nrow(ref$parts), " Part records in ", parts_file,
         ", found ", nrow(parts_records), ".", call. = FALSE)
  }

  parts_refs <- parse_wos_cr(parts_file)
  parts_refs <- parts_refs[parts_refs$UT %in% ref$parts$UT, , drop = FALSE]
  if (length(unique(parts_refs$UT)) != nrow(ref$parts)) {
    stop("The cited references of every Part must be present.", call. = FALSE)
  }

  citing_records <- read_wos_records(citing_file)
  citing_refs <- parse_wos_cr(citing_file)
  n_retrieved <- length(unique(citing_refs$UT))

  part_pattern <- paste(toupper(ref$parts$doi), collapse = "|")
  part_citers <- unique(citing_refs$UT[grepl(part_pattern, toupper(citing_refs$CR))])
  if (length(part_citers) == 0L) {
    stop("No citing record cites a Part by DOI.", call. = FALSE)
  }

  list(
    parts_records  = parts_records,
    parts_refs     = add_ref_keys(parts_refs, ref$merge_rules),
    citing_records = citing_records[citing_records$UT %in% part_citers, , drop = FALSE],
    citing_refs    = add_ref_keys(citing_refs[citing_refs$UT %in% part_citers, , drop = FALSE],
                                  ref$merge_rules),
    n_retrieved    = n_retrieved
  )
}
