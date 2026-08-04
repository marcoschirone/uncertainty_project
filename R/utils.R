parse_wos_cr <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  if (length(lines) > 0 && startsWith(lines[1], "\ufeff")) {
    lines[1] <- substring(lines[1], 2)
  }

  results_ut <- character(0)
  results_cr <- character(0)

  current_ut  <- NA_character_
  current_tag <- ""
  cr_refs     <- character(0)

  for (line in lines) {
    raw <- trimws(line, which = "right")

    if (raw == "ER") {
      if (!is.na(current_ut) && length(cr_refs) > 0) {
        results_ut <- c(results_ut, rep(current_ut, length(cr_refs)))
        results_cr <- c(results_cr, cr_refs)
      }

      current_ut  <- NA_character_
      current_tag <- ""
      cr_refs     <- character(0)
      next
    }

    if (nchar(raw) >= 3 && grepl("^[A-Z]{2} ", substr(raw, 1, 3))) {
      tag   <- substr(raw, 1, 2)
      value <- trimws(substr(raw, 4, nchar(raw)))
      current_tag <- tag

      if (tag == "UT") {
        current_ut <- value
      } else if (tag == "CR") {
        cr_refs <- c(cr_refs, value)
      }

    } else if (startsWith(raw, "   ") && current_tag == "CR") {
      cr_refs <- c(cr_refs, trimws(raw))
    }
  }

  data.frame(
    UT = results_ut,
    CR = results_cr,
    stringsAsFactors = FALSE
  )
}

normalize_ref <- function(cr_string) {
  sapply(cr_string, function(x) {
    parts <- stringr::str_split(x, ",\\s*", simplify = TRUE)

    if (ncol(parts) >= 3) {
      key <- paste(parts[1, 1:3], collapse = ", ")
    } else {
      key <- parts[1, 1]
    }

    toupper(stringr::str_squish(key))
  }, USE.NAMES = FALSE)
}

apply_merges <- function(keys, rules) {
  idx <- match(keys, names(rules))
  ifelse(is.na(idx), keys, rules[idx])
}

is_generic <- function(key) {
  startsWith(key, "[ANONYMOUS]") |
    startsWith(key, "ANONYMOUS,") |
    startsWith(key, "*")
}

# A normalised key is unresolvable when it carries no publication year.
# normalize_ref() builds the key from the first three comma-separated fields of
# the CR string; when a reference has fewer than three fields it falls back to
# the author name alone. In this corpus that happens for "in press" citations
# such as "WILSON TD, IN PRESS INFORMATI 2" (Part 4) and
# "SPINK A, IN PRESS INFORMATION" (Part 3), which reduce to "WILSON TD" and
# "SPINK A". Such keys cannot match any citing paper's reference list and so
# cannot contribute to bibliographic coupling. They are excluded on the same
# grounds as generic and anonymous references.
is_unresolvable <- function(key) {
  !grepl("(^|[^0-9])(1[6-9]|20)[0-9]{2}([^0-9]|$)", key)
}

safe_pct <- function(x, denom, digits = 1) {
  if (length(denom) != 1) {
    stop("denom must be a single scalar value", call. = FALSE)
  }
  if (is.na(denom) || denom == 0) {
    return(rep(NA_real_, length(x)))
  }
  round(100 * x / denom, digits)
}
