# events.R - HALO event generation and ingest.
#
# Events are a Poisson stream over the window. Each day draws Poisson(day_rate)
# day events and Poisson(night_rate) night events. A single `rate` is split
# 50/50 across day and night unless separate rates are given.
#
# Events are represented in long form: one row per event with an integer
# `day_idx` (0-based), a `date`, and a `shift_type` of "day"/"night".

EVENT_SHIFTS <- c("day", "night")

# ---------------------------------------------------------------------------
# Generation (exported)
# ---------------------------------------------------------------------------

#' Generate a Poisson HALO event stream
#'
#' @param n_days Integer window length.
#' @param rate Numeric events per day, split 50/50 day/night. Ignored when both
#'   `day_rate` and `night_rate` are supplied.
#' @param seed Integer RNG seed.
#' @param day_rate,night_rate Optional numeric per-day rates for each shift.
#'   Supply both to override `rate`.
#' @param start_date Character or Date; day 0 of the window.
#' @return A data frame with columns `day_idx` (integer, 0-based), `date`
#'   (Date), and `shift_type` (`"day"`/`"night"`), sorted by day.
#' @examples
#' ev <- generate_events(365, rate = 0.1, seed = 1)
#' nrow(ev)
#' @export
generate_events <- function(n_days, rate, seed = 42,
                            day_rate = NULL, night_rate = NULL,
                            start_date = "2024-01-01") {
  set.seed(seed)
  start <- as.Date(start_date)

  if (!is.null(day_rate) && !is.null(night_rate)) {
    day_lambda <- day_rate
    night_lambda <- night_rate
  } else {
    day_lambda <- rate / 2
    night_lambda <- rate / 2
  }

  if ((day_lambda + night_lambda) > 0.2) {
    warning("Event rate is high (>20% of days have an event on average). ",
            "Verify this matches your HALO event frequency.")
  }

  day_counts <- stats::rpois(n_days, day_lambda)
  night_counts <- stats::rpois(n_days, night_lambda)
  day_ax <- 0:(n_days - 1)

  events <- rbind(
    data.frame(day_idx = rep(day_ax, day_counts), shift_type = "day",
               stringsAsFactors = FALSE),
    data.frame(day_idx = rep(day_ax, night_counts), shift_type = "night",
               stringsAsFactors = FALSE)
  )
  events <- events[order(events$day_idx, events$shift_type), , drop = FALSE]
  events$date <- start + events$day_idx
  rownames(events) <- NULL
  events[, c("day_idx", "date", "shift_type")]
}

# ---------------------------------------------------------------------------
# Ingest (exported)
# ---------------------------------------------------------------------------

#' Load HALO events from a data frame or CSV file
#'
#' Required columns: `date` (YYYY-MM-DD) and `shift_type` (`"day"`/`"night"`).
#' Events outside the window are dropped with a warning.
#'
#' @param x A data frame, or a path to a CSV file, with the required columns.
#' @param n_days Integer window length.
#' @param start_date Character or Date; day 0 of the window.
#' @return A data frame with columns `day_idx`, `date`, `shift_type`.
#' @export
load_events <- function(x, n_days, start_date = "2024-01-01") {
  df <- if (is.character(x)) utils::read.csv(x, stringsAsFactors = FALSE) else x
  names(df) <- tolower(trimws(names(df)))

  missing <- setdiff(c("date", "shift_type"), names(df))
  if (length(missing)) {
    stop(sprintf("Missing required column(s): %s. Required: date, shift_type.",
                 paste(sort(missing), collapse = ", ")))
  }

  st <- tolower(trimws(as.character(df$shift_type)))
  bad <- setdiff(unique(st), EVENT_SHIFTS)
  if (length(bad)) {
    stop(sprintf("Invalid shift_type value(s): %s. Allowed: day, night.",
                 paste(sort(bad), collapse = ", ")))
  }
  df$shift_type <- st

  start <- as.Date(start_date)
  d <- as.Date(as.character(df$date))
  if (anyNA(d)) stop("Could not parse 'date' column - expected format YYYY-MM-DD.")
  df$date <- d
  df$day_idx <- as.integer(d - start)

  in_window <- df$day_idx >= 0 & df$day_idx < n_days
  if (any(!in_window)) {
    warning(sprintf("%d event(s) fall outside the window and were excluded.",
                    sum(!in_window)))
  }
  df <- df[in_window, , drop = FALSE]
  rownames(df) <- NULL
  df[, c("day_idx", "date", "shift_type")]
}
