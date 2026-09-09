# exposure.R - Exposure computation and per-provider gap statistics.
#
# A provider is "exposed" on a day when they are on shift AND a HALO event
# occurred on that shift that day (simple shift-matched join). From each
# provider's exposure days we derive inter-exposure gap statistics, matching
# the methodology in PMID 41633464.
#
# Conventions: `schedule` is a (providers x days) character matrix of
# "d"/"n"/"o". `events` is a data frame with an integer `day_idx` (0-based, to
# mirror the reference implementation) and a `shift_type` of "day"/"night".

# ---------------------------------------------------------------------------
# Simple shift-matched join
# ---------------------------------------------------------------------------

#' Shift-matched exposure join
#'
#' Day events expose providers on a day shift; night events expose providers on
#' a night shift, on the matching day.
#'
#' @param schedule (providers x days) character matrix of "d"/"n"/"o".
#' @param events Data frame with integer `day_idx` (0-based) and `shift_type`.
#' @param n_days Integer window length.
#' @return Logical (providers x days) exposure matrix.
#' @keywords internal
#' @noRd
simple_join <- function(schedule, events, n_days) {
  n_providers <- nrow(schedule)
  exposure <- matrix(FALSE, nrow = n_providers, ncol = n_days)

  day_idx <- events$day_idx[events$shift_type == "day"]
  night_idx <- events$day_idx[events$shift_type == "night"]

  # Keep only events inside the window.
  day_idx <- day_idx[day_idx >= 0 & day_idx < n_days]
  night_idx <- night_idx[night_idx >= 0 & night_idx < n_days]

  working_day <- schedule == "d"
  working_night <- schedule == "n"

  if (length(day_idx)) {
    cols <- day_idx + 1L  # 0-based day index -> 1-based column
    exposure[, cols] <- exposure[, cols] | working_day[, cols]
  }
  if (length(night_idx)) {
    cols <- night_idx + 1L
    exposure[, cols] <- exposure[, cols] | working_night[, cols]
  }

  exposure
}

# ---------------------------------------------------------------------------
# Per-provider gap statistics
# ---------------------------------------------------------------------------

#' Inter-exposure gap statistics for one provider
#'
#' The gap set is: lead-in (start to first exposure), the between-event gaps,
#' and trail-out (last exposure to window end). A provider with zero exposures
#' has a single gap equal to `n_days`; one exposure yields two gaps (lead-in and
#' trail-out). Quantiles use type-7 (the default), matching numpy's percentile.
#'
#' @param exposure_row Logical vector of length `n_days` for one provider.
#' @param threshold Integer readiness threshold in days.
#' @param n_days Integer window length.
#' @return A one-row list of gap statistics.
#' @keywords internal
#' @noRd
compute_gaps <- function(exposure_row, threshold, n_days) {
  exposure_days <- which(exposure_row) - 1L  # 0-based day indices
  n <- length(exposure_days)

  if (n == 0) {
    gaps <- as.numeric(n_days)
  } else {
    lead_in   <- as.numeric(exposure_days[1])
    trail_out <- as.numeric(n_days - 1 - exposure_days[n])
    between   <- if (n >= 2) as.numeric(diff(exposure_days)) else numeric(0)
    gaps <- c(lead_in, between, trail_out)
  }

  t2first <- if (n > 0) as.integer(exposure_days[1]) else NA_integer_

  list(
    n_events   = n,
    t2first    = t2first,
    gap_min    = min(gaps),
    gap_q25    = as.numeric(stats::quantile(gaps, 0.25, type = 7, names = FALSE)),
    gap_median = stats::median(gaps),
    gap_mean   = mean(gaps),
    gap_q75    = as.numeric(stats::quantile(gaps, 0.75, type = 7, names = FALSE)),
    gap_max    = max(gaps),
    max_gap_exceeds_threshold = max(gaps) > threshold
  )
}

# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------

#' Build the exposure matrix and per-provider results
#'
#' @param sim A `halo_sim` object with `schedule`, `events`, `providers`, and
#'   `readiness_threshold_days` set.
#' @return A list with `exposure_matrix` (logical providers x days) and
#'   `results_df` (per-provider gap statistics).
#' @keywords internal
#' @noRd
compute_exposure <- function(sim) {
  schedule <- sim$schedule
  n_providers <- nrow(schedule)
  n_days <- ncol(schedule)

  exposure_matrix <- simple_join(schedule, sim$events, n_days)

  rows <- vector("list", n_providers)
  for (i in seq_len(n_providers)) {
    stats <- compute_gaps(exposure_matrix[i, ], sim$readiness_threshold_days, n_days)
    stats$provider_id <- sim$providers[i]
    rows[[i]] <- as.data.frame(stats, stringsAsFactors = FALSE)
  }

  results_df <- do.call(rbind, rows)
  cols <- c("provider_id", "n_events", "t2first",
            "gap_min", "gap_q25", "gap_median", "gap_mean", "gap_q75", "gap_max",
            "max_gap_exceeds_threshold")
  results_df <- results_df[, cols]

  list(exposure_matrix = exposure_matrix, results_df = results_df)
}
