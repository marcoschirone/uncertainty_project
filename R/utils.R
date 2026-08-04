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

safe_pct <- function(x, denom, digits = 1) {
  if (length(denom) != 1) {
    stop("denom must be a single scalar value", call. = FALSE)
  }
  if (is.na(denom) || denom == 0) {
    return(rep(NA_real_, length(x)))
  }
  round(100 * x / denom, digits)
}
