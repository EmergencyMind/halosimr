# simulation.R - The halo_sim object and the single-run pipeline.
#
# halo_sim() bundles the inputs and configuration into one classed list;
# hsrun() executes stages A-H and returns the object with the output matrices
# and aggregate curves attached.

#' Construct a HALO simulation
#'
#' @param schedule Character (providers x days) matrix of `"d"`/`"n"`/`"o"`,
#'   e.g. from [generate_schedule()].
#' @param events Data frame of events with `day_idx` and `shift_type`, e.g. from
#'   [generate_events()].
#' @param providers Optional character vector of provider ids (defaults to
#'   `P0001`, `P0002`, ...).
#' @param seed Integer seed for the warmup draw.
#' @param readiness_model One of `"binary"`, `"exponential"`, `"ebbinghaus"`,
#'   `"step"`.
#' @param readiness_threshold_days Integer threshold for `binary`/`step` and the
#'   gap exceed flag.
#' @param readiness_half_life_days Numeric half-life for `exponential`.
#' @param ebbinghaus_b Numeric shape for `ebbinghaus`.
#' @param step_partial_value,step_t2_days Partial value and second threshold for
#'   `step`.
#' @param training_program One of `"none"`, `"monthly"`, `"bimonthly"`,
#'   `"quarterly"`, `"custom"`.
#' @param training_interval_days Integer interval for `custom`.
#' @param training_start_day Integer 0-based day of first training.
#' @return An object of class `halo_sim`.
#' @examples
#' sched <- generate_schedule(20, 90, "3/7 Day", seed = 1)
#' ev <- generate_events(90, rate = 0.2, seed = 1)
#' sim <- halo_sim(sched, ev, readiness_model = "exponential")
#' sim <- hsrun(sim)
#' @export
halo_sim <- function(schedule, events, providers = NULL, seed = 42,
                     readiness_model = "binary",
                     readiness_threshold_days = 90,
                     readiness_half_life_days = 60,
                     ebbinghaus_b = 0.05,
                     step_partial_value = 0.5,
                     step_t2_days = 180,
                     training_program = "none",
                     training_interval_days = 28,
                     training_start_day = 0) {
  if (!is.matrix(schedule)) stop("`schedule` must be a matrix.")
  if (is.null(providers)) providers <- sprintf("P%04d", seq_len(nrow(schedule)))
  if (length(providers) != nrow(schedule)) {
    stop("length(providers) must equal nrow(schedule).")
  }
  if (!all(c("day_idx", "shift_type") %in% names(events))) {
    stop("`events` must have columns `day_idx` and `shift_type`.")
  }

  structure(list(
    schedule = schedule, events = events, providers = providers,
    n_days = ncol(schedule), n_providers = nrow(schedule), seed = seed,
    readiness_model = readiness_model,
    readiness_threshold_days = readiness_threshold_days,
    readiness_half_life_days = readiness_half_life_days,
    ebbinghaus_b = ebbinghaus_b,
    step_partial_value = step_partial_value, step_t2_days = step_t2_days,
    training_program = training_program,
    training_interval_days = training_interval_days,
    training_start_day = training_start_day
  ), class = "halo_sim")
}

#' Run a HALO simulation
#'
#' Executes the pipeline: on-shift mask -> exposure + gap stats -> warmup ->
#' training -> combined -> readiness -> daily aggregates.
#'
#' @param sim A `halo_sim` object from [halo_sim()].
#' @return The `halo_sim` object with output fields attached: `exposure_matrix`,
#'   `results_df`, `training_matrix`, `combined_matrix`, `readiness_matrix`,
#'   `proportion_ready_on_shift`, `proportion_ready_all`.
#' @export
hsrun <- function(sim) {
  # A. on-shift mask
  sim$on_shift_mask <- sim$schedule == "d" | sim$schedule == "n"

  # B/C. exposure + per-provider gap stats
  exp <- compute_exposure(sim)
  sim$exposure_matrix <- exp$exposure_matrix
  sim$results_df <- exp$results_df

  # D. warmup offsets (left-censoring correction)
  initial_last <- compute_initial_last(sim$exposure_matrix, sim$n_days, sim$seed)

  # E. training, then combined reset matrix
  sim$training_matrix <- compute_training(sim)
  sim$combined_matrix <- sim$exposure_matrix | sim$training_matrix

  # F/G. readiness
  sim$readiness_matrix <- compute_readiness(sim, initial_last = initial_last)

  # H. daily aggregates
  osm <- sim$on_shift_mask
  on_counts <- colSums(osm)
  prop_on <- colSums(sim$readiness_matrix * osm) / on_counts
  prop_on[on_counts == 0] <- NA_real_
  sim$proportion_ready_on_shift <- prop_on
  sim$proportion_ready_all <- colMeans(sim$readiness_matrix)

  sim
}

#' @export
print.halo_sim <- function(x, ...) {
  cat(sprintf("<halo_sim>  %d providers x %d days\n", x$n_providers, x$n_days))
  cat(sprintf("  readiness: %s   training: %s\n",
              x$readiness_model, x$training_program))
  if (!is.null(x$readiness_matrix)) {
    mean_on <- mean(x$proportion_ready_on_shift, na.rm = TRUE)
    pct_exc <- 100 * mean(x$results_df$max_gap_exceeds_threshold)
    cat(sprintf("  mean on-shift readiness: %.3f\n", mean_on))
    cat(sprintf("  providers exceeding gap threshold: %.1f%%\n", pct_exc))
  } else {
    cat("  (not yet run - call hsrun())\n")
  }
  invisible(x)
}
