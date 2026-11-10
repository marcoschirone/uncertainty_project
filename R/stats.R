# Statistical helpers.

safe_pct <- function(x, denom, digits = 1) {
  if (length(denom) != 1) stop("denom must be a single value", call. = FALSE)
  if (is.na(denom) || denom == 0) return(rep(NA_real_, length(x)))
  round(100 * x / denom, digits)
}

#' Wilson score interval for a proportion
wilson_ci <- function(k, n, z = 1.96) {
  if (n == 0) return(c(NA_real_, NA_real_))
  p <- k / n
  den <- 1 + z^2 / n
  centre <- (p + z^2 / (2 * n)) / den
  half <- z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / den
  c(centre - half, centre + half)
}

#' Percentile bootstrap interval for a mean, resampling papers
boot_mean_ci <- function(x, R = 2000, seed = 20260930) {
  x <- x[!is.na(x)]
  if (length(x) < 2) return(c(NA_real_, NA_real_))
  set.seed(seed)
  b <- replicate(R, mean(sample(x, replace = TRUE)))
  stats::quantile(b, c(0.025, 0.975), names = FALSE)
}

#' Pooled ratio sum(num) / sum(den) with a paper-level bootstrap interval
pooled_ratio_ci <- function(num, den, R = 2000, seed = 20260930) {
  est <- sum(num) / sum(den)
  set.seed(seed)
  b <- replicate(R, {
    i <- sample(seq_along(num), replace = TRUE)
    sum(num[i]) / sum(den[i])
  })
  c(est, stats::quantile(b, c(0.025, 0.975), names = FALSE, na.rm = TRUE))
}

#' Cramer's V of a contingency table, after dropping empty rows and columns
cramers_v <- function(tab) {
  tab <- tab[rowSums(tab) > 0, colSums(tab) > 0, drop = FALSE]
  chi <- suppressWarnings(stats::chisq.test(tab, correct = FALSE))
  sqrt(unname(chi$statistic) / (sum(tab) * (min(dim(tab)) - 1)))
}

#' Cohen's kappa for two nominal codings
cohen_kappa <- function(a, b, levels) {
  a <- factor(a, levels = levels)
  b <- factor(b, levels = levels)
  keep <- !is.na(a) & !is.na(b)
  a <- a[keep]
  b <- b[keep]
  if (!length(a)) return(c(agreement = NA_real_, kappa = NA_real_, n = 0))
  tab <- table(a, b)
  n <- sum(tab)
  po <- sum(diag(tab)) / n
  pe <- sum((rowSums(tab) / n) * (colSums(tab) / n))
  k <- if (isTRUE(all.equal(1 - pe, 0))) NA_real_ else (po - pe) / (1 - pe)
  c(agreement = po, kappa = k, n = n)
}

#' Agreement coefficients for two coders of the same items (nominal codes)
#'
#' Returns raw agreement, Cohen's kappa, Scott's pi, Krippendorff's alpha
#' (nominal, two coders, no missing values) and Gwet's AC1. Chance agreement
#' for pi, alpha and AC1 uses the categories that occur in either coding.
agreement_coefficients <- function(a, b) {
  keep <- !is.na(a) & !is.na(b)
  a <- as.character(a[keep])
  b <- as.character(b[keep])
  n <- length(a)
  if (!n) {
    return(c(n = 0, agreement = NA_real_, cohen_kappa = NA_real_, scott_pi = NA_real_,
             krippendorff_alpha = NA_real_, gwet_ac1 = NA_real_))
  }
  cats <- sort(unique(c(a, b)))
  pa <- vapply(cats, function(k) mean(a == k), numeric(1))
  pb <- vapply(cats, function(k) mean(b == k), numeric(1))
  pm <- (pa + pb) / 2
  po <- mean(a == b)
  chance <- function(pe) if (isTRUE(all.equal(1 - pe, 0))) NA_real_ else (po - pe) / (1 - pe)
  kappa <- chance(sum(pa * pb))
  pi <- chance(sum(pm^2))
  q <- length(cats)
  ac1 <- if (q < 2) NA_real_ else chance(sum(pm * (1 - pm)) / (q - 1))
  # Krippendorff: 2n pairable values; observed disagreement from the coincidence matrix
  m <- 2 * n
  nk <- vapply(cats, function(k) sum(a == k) + sum(b == k), numeric(1))
  de <- (m^2 - sum(nk^2)) / (m * (m - 1))
  do <- 2 * sum(a != b) / m
  alpha <- if (isTRUE(all.equal(de, 0))) NA_real_ else 1 - do / de
  c(n = n, agreement = po, cohen_kappa = kappa, scott_pi = pi,
    krippendorff_alpha = alpha, gwet_ac1 = ac1)
}

year_window <- function(py, settings) {
  cut(py, breaks = settings$year_breaks, labels = settings$year_labels)
}
