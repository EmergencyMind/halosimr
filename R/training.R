# training.R - Training program simulation (scheduled programs only).
#
# On each scheduled training day, every on-shift provider receives a training
# event, which counts as a readiness reset. Targeted (readiness-driven)
# training is deferred.

#' Scheduled training matrix
#'
#' Marks TRUE where an on-shift provider trains on a scheduled day
#' (start, start + interval, ...).
#'
#' @param on_shift_mask Logical (providers x days) matrix.
#' @param interval Integer days between training days.
#' @param start Integer 0-based day of the first training.
#' @return Logical (providers x days) matrix.
#' @keywords internal
#' @noRd
scheduled_training <- function(on_shift_mask, interval, start = 0L) {
  n_days <- ncol(on_shift_mask)
  training <- matrix(FALSE, nrow = nrow(on_shift_mask), ncol = n_days)
  if (start <= n_days - 1) {
    days <- seq(start, n_days - 1, by = interval)  # 0-based day indices
    for (t in days) training[, t + 1L] <- on_shift_mask[, t + 1L]
  }
  training
}

#' Compute the training matrix for a simulation
#'
#' @param sim A `halo_sim` object with `on_shift_mask`, `training_program`,
#'   `training_interval_days`, and `training_start_day` set.
#' @return Logical (providers x days) training matrix.
#' @keywords internal
#' @noRd
compute_training <- function(sim) {
  osm <- sim$on_shift_mask
  if (sim$training_program == "none") {
    return(matrix(FALSE, nrow = nrow(osm), ncol = ncol(osm)))
  }
  interval <- switch(sim$training_program,
    monthly   = 30L,
    bimonthly = 60L,
    quarterly = 91L,
    custom    = as.integer(sim$training_interval_days),
    30L
  )
  scheduled_training(osm, interval, as.integer(sim$training_start_day))
}
