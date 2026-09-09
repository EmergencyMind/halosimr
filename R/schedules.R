# schedules.R - Provider schedule generation and ingest.
#
# Every provider gets an independently randomised schedule of length n_days,
# each cell one of "d" (day shift), "n" (night shift), "o" (off). Six schedule
# types plus a custom 28-day pattern and file/data-frame ingest.

# ---------------------------------------------------------------------------
# Catalogue and constants
# ---------------------------------------------------------------------------

SCHEDULE_TYPES <- c(
  "3/7 Day", "3/7 Night", "4/7 Day", "4/7 Night",
  "Progressive (day & night mix)", "Random"
)
DEFAULT_SCHEDULE_TYPE <- "3/7 Day"

# Empirical d/n/o weights from the paper (PMID 41633464).
DEFAULT_WEIGHTS <- c(d = 0.246, n = 0.230, o = 0.524)

MAX_PROVIDERS <- 5000L
WARN_PROVIDERS <- 1000L

VALID_UPLOAD_SHIFTS <- c("d", "day", "n", "night", "o", "off")
NORM_SHIFT <- c(d = "d", day = "d", n = "n", night = "n", o = "o", off = "o")

# ---------------------------------------------------------------------------
# Single-provider generator (internal)
# ---------------------------------------------------------------------------

#' Generate one provider's schedule
#'
#' Draws from the global RNG state, so the caller seeds once before looping over
#' the population. If `weights` is supplied, every day is drawn independently
#' from those d/n/o probabilities regardless of `schedule_type`.
#'
#' @param n_days Integer window length.
#' @param schedule_type One of [SCHEDULE_TYPES].
#' @param weights Optional named numeric with elements d/n/o.
#' @return Character vector of length `n_days`.
#' @keywords internal
#' @noRd
generate_one <- function(n_days, schedule_type, weights = NULL) {
  if (!is.null(weights)) {
    choices <- c("d", "n", "o")
    probs <- vapply(choices, function(c) {
      v <- weights[[c]]
      if (is.null(v) || is.na(v)) 0 else as.numeric(v)
    }, numeric(1))
    probs <- probs / sum(probs)
    return(sample(choices, size = n_days, replace = TRUE, prob = probs))
  }

  sched <- rep("o", n_days)

  if (schedule_type %in% c("3/7 Day", "3/7 Night", "4/7 Day", "4/7 Night")) {
    k <- if (startsWith(schedule_type, "3")) 3L else 4L
    char <- if (grepl("Day", schedule_type)) "d" else "n"
    day <- 0L  # 0-based week start
    while (day < n_days) {
      end <- min(day + 7L, n_days)
      week_len <- end - day
      k_actual <- min(k, week_len)
      positions <- sample.int(week_len, size = k_actual, replace = FALSE)  # 1..week_len
      sched[day + positions] <- char
      day <- day + 7L
    }

  } else if (schedule_type == "Progressive (day & night mix)") {
    day <- 0L
    while (day < n_days) {
      end <- min(day + 7L, n_days)
      week_len <- end - day
      k <- sample(3:4, 1)             # 3 or 4 shifts this week
      k_actual <- min(k, week_len)
      positions <- sample.int(week_len, size = k_actual, replace = FALSE)
      sched[day + positions] <- sample(c("d", "n"), size = k_actual, replace = TRUE)
      day <- day + 7L
    }

  } else if (schedule_type == "Random") {
    choices <- c("d", "n", "o")
    probs <- DEFAULT_WEIGHTS[choices]
    probs <- probs / sum(probs)
    sched <- sample(choices, size = n_days, replace = TRUE, prob = probs)
  }

  sched
}

# ---------------------------------------------------------------------------
# Population schedule (exported)
# ---------------------------------------------------------------------------

#' Generate a provider schedule matrix
#'
#' Each provider receives an independently randomised schedule satisfying the
#' chosen type. Seeding is applied once at the population level so results are
#' reproducible for a given set of inputs.
#'
#' @param n_providers Integer number of providers (capped at 5000).
#' @param n_days Integer window length in days.
#' @param schedule_type One of `"3/7 Day"`, `"3/7 Night"`, `"4/7 Day"`,
#'   `"4/7 Night"`, `"Progressive (day & night mix)"`, `"Random"`. The `"Random"`
#'   type draws each day from the paper's empirical weights
#'   (d = 0.246, n = 0.230, o = 0.524); pass `weights` to override, e.g.
#'   `c(d = 1/3, n = 1/3, o = 1/3)` for an equal split.
#' @param seed Integer RNG seed.
#' @param weights Optional named numeric with elements `d`, `n`, `o`. When
#'   supplied, every provider-day is drawn from these probabilities and
#'   `schedule_type` is ignored.
#' @return A character (providers x days) matrix of `"d"`/`"n"`/`"o"`.
#' @examples
#' sched <- generate_schedule(10, 28, "3/7 Day", seed = 1)
#' table(sched)
#' @export
generate_schedule <- function(n_providers, n_days,
                              schedule_type = DEFAULT_SCHEDULE_TYPE,
                              seed = 42, weights = NULL) {
  if (n_providers > MAX_PROVIDERS) {
    warning(sprintf("Population capped at %d providers.", MAX_PROVIDERS))
    n_providers <- MAX_PROVIDERS
  }
  if (is.null(weights) && !(schedule_type %in% SCHEDULE_TYPES)) {
    warning(sprintf("Unknown schedule type '%s'; using '%s'.",
                    schedule_type, DEFAULT_SCHEDULE_TYPE))
    schedule_type <- DEFAULT_SCHEDULE_TYPE
  }

  set.seed(seed)
  schedule <- matrix("o", nrow = n_providers, ncol = n_days)
  for (i in seq_len(n_providers)) {
    schedule[i, ] <- generate_one(n_days, schedule_type, weights = weights)
  }
  schedule
}

# ---------------------------------------------------------------------------
# Custom 28-day pattern (exported)
# ---------------------------------------------------------------------------

#' Build schedules by tiling a 28-day pattern
#'
#' Repeats a 28-character d/n/o template across the window. Every provider gets
#' the same schedule. Shorter patterns are padded with `"o"`; longer ones are
#' truncated to 28.
#'
#' @param n_providers Integer number of providers (capped at 5000).
#' @param n_days Integer window length.
#' @param pattern Character scalar of d/n/o characters (up to 28 used).
#' @return A character (providers x days) matrix.
#' @examples
#' schedule_from_pattern(3, 56, "dddoooonnnooooo")[1, 1:14]
#' @export
schedule_from_pattern <- function(n_providers, n_days, pattern) {
  if (n_providers > MAX_PROVIDERS) {
    warning(sprintf("Population capped at %d providers.", MAX_PROVIDERS))
    n_providers <- MAX_PROVIDERS
  }
  pattern <- substr(paste0(substr(pattern, 1, 28), strrep("o", 28)), 1, 28)
  base <- strsplit(pattern, "")[[1]]
  repeats <- n_days %/% 28 + 2
  row <- rep(base, repeats)[seq_len(n_days)]
  matrix(row, nrow = n_providers, ncol = n_days, byrow = TRUE)
}

# ---------------------------------------------------------------------------
# Ingest (exported)
# ---------------------------------------------------------------------------

#' Load a schedule from a data frame or CSV file
#'
#' Required columns: `provider_id`, `date` (YYYY-MM-DD), `shift_type` (one of
#' d/day/n/night/o/off). Provider-days missing from the input default to `"o"`.
#'
#' @param x A data frame, or a path to a CSV file, with the required columns.
#' @param n_days Integer window length.
#' @param start_date Character or Date; day 0 of the window.
#' @return A list with `schedule` (character providers x days matrix) and
#'   `providers` (character vector of ids, sorted).
#' @export
load_schedule <- function(x, n_days, start_date = "2024-01-01") {
  df <- if (is.character(x)) utils::read.csv(x, stringsAsFactors = FALSE) else x
  names(df) <- tolower(trimws(names(df)))

  required <- c("provider_id", "date", "shift_type")
  missing <- setdiff(required, names(df))
  if (length(missing)) {
    stop(sprintf("Missing required column(s): %s. Required: provider_id, date, shift_type.",
                 paste(sort(missing), collapse = ", ")))
  }

  st <- tolower(trimws(as.character(df$shift_type)))
  bad <- setdiff(unique(st), VALID_UPLOAD_SHIFTS)
  if (length(bad)) {
    stop(sprintf("Invalid shift_type value(s): %s. Allowed: d, day, n, night, o, off.",
                 paste(sort(bad), collapse = ", ")))
  }
  df$shift_type <- unname(NORM_SHIFT[st])

  start <- as.Date(start_date)
  d <- as.Date(as.character(df$date))
  if (anyNA(d)) stop("Could not parse 'date' column - expected format YYYY-MM-DD.")
  df$day_idx <- as.integer(d - start)

  providers <- sort(unique(as.character(df$provider_id)))
  if (length(providers) > MAX_PROVIDERS) {
    warning(sprintf("File contains more than %d providers; truncated.", MAX_PROVIDERS))
    providers <- providers[seq_len(MAX_PROVIDERS)]
  }
  p_idx <- stats::setNames(seq_along(providers), providers)

  schedule <- matrix("o", nrow = length(providers), ncol = n_days)
  for (r in seq_len(nrow(df))) {
    pid <- as.character(df$provider_id[r])
    di <- df$day_idx[r]
    if (is.na(p_idx[pid]) || di < 0 || di >= n_days) next
    schedule[p_idx[pid], di + 1L] <- df$shift_type[r]
  }

  n_off_default <- sum(schedule == "o")
  total <- length(providers) * n_days
  if (total > 0 && n_off_default / total > 0.1) {
    warning(sprintf("%d provider-days (%.0f%%) defaulted to 'off' from missing rows.",
                    n_off_default, 100 * n_off_default / total))
  }

  list(schedule = schedule, providers = providers)
}
