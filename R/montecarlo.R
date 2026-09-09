# montecarlo.R - Repeat a run over N random seeds and aggregate to bands.
#
# Monte Carlo needs fresh random inputs each pass, so the caller supplies two
# generator closures that each take a seed and return a schedule / events. Each
# seed runs a baseline arm and, when a training program is named, a trained arm;
# per-day readiness is aggregated into a percentile band, and the two arms give
# lift. Per-run gap_max is stored so any threshold sweep is derived on demand.

#' Run a Monte Carlo ensemble of HALO simulations
#'
#' @param n Integer number of runs.
#' @param schedule_fn Function of one argument (a seed) returning a schedule
#'   matrix, e.g. `function(s) generate_schedule(200, 365, "3/7 Day", seed = s)`.
#' @param events_fn Function of one argument (a seed) returning an events data
#'   frame, e.g. `function(s) generate_events(365, rate = 0.1, seed = s)`.
#' @param training_program Program for the trained arm. `"none"` runs the
#'   baseline only (no lift).
#' @param providers Optional provider ids passed to [halo_sim()].
#' @param probs Length-3 numeric of lower/median/upper quantiles for the band.
#' @param seeds Optional integer vector of length `n`; defaults to `1:n`.
#' @param ... Further arguments passed to [halo_sim()] (readiness model and
#'   parameters, `training_interval_days`, etc.).
#' @return An object of class `halo_mc` with the per-run readiness matrices, the
#'   baseline band (and trained band + `lift` when a program is set), stored
#'   per-run `gap_max`, and a per-run `summary` data frame.
#' @examples
#' mc <- hsrunmc(
#'   n = 10,
#'   schedule_fn = function(s) generate_schedule(100, 180, "3/7 Day", seed = s),
#'   events_fn   = function(s) generate_events(180, rate = 0.15, seed = s),
#'   readiness_model = "exponential", training_program = "monthly"
#' )
#' mc
#' @export
hsrunmc <- function(n, schedule_fn, events_fn, training_program = "none",
                    providers = NULL, probs = c(0.1, 0.5, 0.9),
                    seeds = NULL, ...) {
  if (length(probs) != 3) stop("`probs` must have length 3 (lower, median, upper).")
  if (is.null(seeds)) seeds <- seq_len(n)
  extra <- list(...)
  trained <- training_program != "none"

  base_curves <- vector("list", n)
  train_curves <- if (trained) vector("list", n) else NULL
  gap_max <- vector("list", n)
  pct_exceed <- numeric(n)
  median_gap <- numeric(n)
  mean_readiness <- numeric(n)

  for (i in seq_len(n)) {
    s <- seeds[i]
    sched <- suppressWarnings(schedule_fn(s))
    ev    <- suppressWarnings(events_fn(s))

    base <- hsrun(do.call(halo_sim, c(list(schedule = sched, events = ev,
      providers = providers, seed = s, training_program = "none"), extra)))
    base_curves[[i]] <- base$proportion_ready_on_shift
    gap_max[[i]] <- base$results_df$gap_max
    pct_exceed[i] <- 100 * mean(base$results_df$max_gap_exceeds_threshold)
    median_gap[i] <- stats::median(base$results_df$gap_median, na.rm = TRUE)
    mean_readiness[i] <- mean(base$proportion_ready_on_shift, na.rm = TRUE)

    if (trained) {
      tr <- hsrun(do.call(halo_sim, c(list(schedule = sched, events = ev,
        providers = providers, seed = s, training_program = training_program), extra)))
      train_curves[[i]] <- tr$proportion_ready_on_shift
    }
  }

  R_base <- do.call(rbind, base_curves)
  n_days <- ncol(R_base)
  band <- .mc_band(R_base, probs, n_days)

  band_trained <- NULL
  lift <- NULL
  if (trained) {
    R_train <- do.call(rbind, train_curves)
    band_trained <- .mc_band(R_train, probs, n_days)
    lift <- band_trained$med - band$med
  } else {
    R_train <- NULL
  }

  structure(list(
    n = n, seeds = seeds, n_days = n_days,
    training_program = training_program,
    readiness = R_base, readiness_trained = R_train,
    band = band, band_trained = band_trained, lift = lift,
    gap_max = gap_max,
    summary = data.frame(run = seq_len(n), seed = seeds,
                         pct_exceed = pct_exceed, median_gap = median_gap,
                         mean_readiness = mean_readiness)
  ), class = "halo_mc")
}

# Per-day percentile band across runs (rows = runs, cols = days).
.mc_band <- function(R, probs, n_days) {
  qs <- apply(R, 2, stats::quantile, probs = probs, na.rm = TRUE, names = FALSE)
  data.frame(day = seq_len(n_days), lo = qs[1, ], med = qs[2, ], hi = qs[3, ])
}

#' @export
print.halo_mc <- function(x, ...) {
  cat(sprintf("<halo_mc>  %d runs x %d days\n", x$n, x$n_days))
  cat(sprintf("  training: %s\n", x$training_program))
  cat(sprintf("  baseline median readiness: %.3f\n", mean(x$band$med)))
  if (!is.null(x$lift)) {
    cat(sprintf("  trained median readiness:  %.3f  (mean lift %+.3f)\n",
                mean(x$band_trained$med), mean(x$lift)))
  }
  invisible(x)
}
