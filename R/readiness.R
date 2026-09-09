# readiness.R - Readiness decay models.
#
# Each kernel maps "days since last reset" to a readiness value in [0, 1],
# where 1 is fully ready and 0 is not ready. Inputs may be a scalar, a vector,
# or a (providers x days) matrix; kernels operate elementwise and preserve
# shape. "Last reset" is the most recent day a provider had a live exposure or
# a training event.

# ---------------------------------------------------------------------------
# Exported kernels
# ---------------------------------------------------------------------------

#' Binary readiness
#'
#' Readiness is 1 while days since the last reset is at or below `threshold`,
#' and 0 afterwards. This is the basic model.
#'
#' @param days_since Numeric scalar, vector, or matrix of days since the last
#'   exposure or training reset.
#' @param threshold Integer. Days a provider stays ready after a reset.
#' @return Numeric of the same shape as `days_since`, either 0 or 1.
#' @examples
#' readiness_binary(c(0, 45, 90, 120), threshold = 90)
#' @export
readiness_binary <- function(days_since, threshold = 90) {
  out <- as.numeric(days_since <= threshold)
  if (!is.null(dim(days_since))) dim(out) <- dim(days_since)
  out
}

#' Exponential readiness decay
#'
#' Readiness decays exponentially with a fixed half-life: it halves every
#' `half_life` days since the last reset. Rate is `log(2) / half_life`.
#'
#' @param days_since Numeric scalar, vector, or matrix of days since the last
#'   exposure or training reset.
#' @param half_life Numeric. Days for readiness to halve. Values below 1 are
#'   treated as 1.
#' @return Numeric of the same shape as `days_since`, values in (0, 1].
#' @examples
#' readiness_exponential(c(0, 60, 120), half_life = 60)
#' @export
readiness_exponential <- function(days_since, half_life = 60) {
  lambda <- log(2) / max(half_life, 1)
  exp(-lambda * days_since)
}

#' Ebbinghaus forgetting-curve readiness
#'
#' Readiness follows the Ebbinghaus form `1 / (1 + b * days_since)`, a slower
#' initial decay than exponential with a heavy tail.
#'
#' @param days_since Numeric scalar, vector, or matrix of days since the last
#'   exposure or training reset.
#' @param b Numeric. Shape parameter; larger `b` decays faster.
#' @return Numeric of the same shape as `days_since`, values in (0, 1].
#' @examples
#' readiness_ebbinghaus(c(0, 60, 120), b = 0.05)
#' @export
readiness_ebbinghaus <- function(days_since, b = 0.05) {
  1 / (1 + b * days_since)
}

#' Two-threshold step readiness
#'
#' Readiness is 1 up to `t1` days, a `partial` value between `t1` and `t2`,
#' and 0 beyond `t2`.
#'
#' @param days_since Numeric scalar, vector, or matrix of days since the last
#'   exposure or training reset.
#' @param t1 Integer. Days of full readiness.
#' @param t2 Integer. Days at which partial readiness ends.
#' @param partial Numeric between 0 and 1. Readiness value on the `t1`..`t2` interval.
#' @return Numeric of the same shape as `days_since`: 0, the partial value, or 1.
#' @examples
#' readiness_step(c(0, 90, 150, 200), t1 = 90, t2 = 180, partial = 0.5)
#' @export
readiness_step <- function(days_since, t1 = 90, t2 = 180, partial = 0.5) {
  out <- ifelse(days_since <= t1, 1,
                ifelse(days_since <= t2, partial, 0))
  if (!is.null(dim(days_since))) dim(out) <- dim(days_since)
  out
}

# ---------------------------------------------------------------------------
# Internal: days since last reset (running last-True index)
# ---------------------------------------------------------------------------

#' Days since last reset
#'
#' For each provider on each day, days elapsed since the most recent TRUE in
#' `combined` up to and including that day. Days axis is treated as 0-based
#' internally so the arithmetic matches the reference implementation; only
#' differences are used, so the choice is invisible to callers. Providers with
#' no reset get `n_days + 1` ("never").
#'
#' @param combined Logical (providers x days) matrix: TRUE where a live
#'   exposure or a training event occurred.
#' @param initial_last Optional integer vector (length = providers) of each
#'   provider's last prior reset as a negative day offset (e.g. -30 = 30 days
#'   before day 0). NULL assumes no prior history.
#' @return Integer (providers x days) matrix of days since last reset, clipped
#'   to `[0, n_days + 1]`.
#' @keywords internal
#' @noRd
days_since_last_reset <- function(combined, initial_last = NULL) {
  n_providers <- nrow(combined)
  n_days <- ncol(combined)
  never <- n_days + 1

  last <- matrix(-never, nrow = n_providers, ncol = n_days)

  init_carry <- if (is.null(initial_last)) rep(-never, n_providers) else initial_last

  # Column j holds day index t = j - 1.
  last[, 1] <- ifelse(combined[, 1], 0, init_carry)
  if (n_days >= 2) {
    for (j in 2:n_days) {
      t <- j - 1
      last[, j] <- ifelse(combined[, j], t, last[, j - 1])
    }
  }

  tmat <- matrix(0:(n_days - 1), nrow = n_providers, ncol = n_days, byrow = TRUE)
  days_since <- tmat - last
  days_since[days_since < 0] <- 0
  days_since[days_since > never] <- never
  days_since
}

# ---------------------------------------------------------------------------
# Internal: warmup / left-censoring correction
# ---------------------------------------------------------------------------

#' Estimate pre-window last-exposure offsets
#'
#' Each provider almost certainly had exposures before the simulation window
#' opened. Ignoring that makes everyone look freshly un-ready on day 0. For
#' each provider with in-window exposures, draw a geometric gap from their
#' empirical exposure rate and place their last prior reset that many days
#' before day 0. Providers with zero exposures get "never".
#'
#' @param exposure_matrix Logical (providers x days) matrix of live exposures.
#' @param n_days Integer. Window length.
#' @param seed Integer. Base seed; offset internally so warmup draws differ
#'   from the main simulation stream.
#' @return Integer vector (length = providers) of negative day offsets.
#' @keywords internal
#' @noRd
compute_initial_last <- function(exposure_matrix, n_days, seed) {
  never <- -(n_days + 1)
  n_providers <- nrow(exposure_matrix)
  n_events <- rowSums(exposure_matrix)
  exp_rate <- n_events / n_days

  old_seed <- .Random.seed
  on.exit({ .Random.seed <<- old_seed }, add = TRUE)
  set.seed(seed + 9973L)

  initial_last <- rep(never, n_providers)
  active <- which(exp_rate > 0)
  for (i in active) {
    p <- min(exp_rate[i], 0.999)
    # numpy geometric has support {1,2,...}; R rgeom counts failures {0,1,...}.
    # Add 1 so the mean is 1/p (expected stationary inter-event gap).
    days_since <- stats::rgeom(1, prob = p) + 1L
    initial_last[i] <- -days_since
  }
  initial_last
}

# ---------------------------------------------------------------------------
# Internal: dispatch
# ---------------------------------------------------------------------------

#' Compute the readiness matrix for a simulation
#'
#' Builds days-since-last-reset from the simulation's combined exposure/training
#' matrix, then applies the selected kernel.
#'
#' @param sim A `halo_sim` object with `combined_matrix`, `readiness_model`,
#'   and the kernel parameters set.
#' @param initial_last Optional warmup offsets from [compute_initial_last()].
#' @return Numeric (providers x days) readiness matrix.
#' @keywords internal
#' @noRd
compute_readiness <- function(sim, initial_last = NULL) {
  days_since <- days_since_last_reset(sim$combined_matrix, initial_last = initial_last)

  switch(sim$readiness_model,
    binary      = readiness_binary(days_since, sim$readiness_threshold_days),
    exponential = readiness_exponential(days_since, sim$readiness_half_life_days),
    ebbinghaus  = readiness_ebbinghaus(days_since, sim$ebbinghaus_b),
    step        = readiness_step(days_since, sim$readiness_threshold_days,
                                 sim$step_t2_days, sim$step_partial_value),
    readiness_binary(days_since, sim$readiness_threshold_days)
  )
}
