# plots.R - Four core figures. ggplot2 is a Suggests dependency; each function
# checks for it and returns a ggplot object. Every other view a user might want
# is a one-liner off the tidy data frames in a run object, so only the four
# most-used figures ship here.

# aes() uses bare column names (non-standard evaluation); declare them so
# R CMD check does not flag them as undefined globals. This avoids depending on
# rlang for the .data pronoun.
utils::globalVariables(c("day", "readiness", "gap_max", "n_events",
                         "lo", "hi", "med", "arm"))

.need_ggplot <- function() {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting. Install it with ",
         "install.packages('ggplot2').", call. = FALSE)
  }
}

.need_run <- function(sim) {
  if (is.null(sim$readiness_matrix)) stop("Run hsrun(sim) first.", call. = FALSE)
}

#' Readiness over time (single run)
#'
#' Daily mean readiness across on-shift providers.
#'
#' @param sim A run `halo_sim` object.
#' @return A ggplot object.
#' @export
plot_readiness <- function(sim) {
  .need_ggplot(); .need_run(sim)
  df <- data.frame(day = seq_len(sim$n_days),
                   readiness = sim$proportion_ready_on_shift)
  ggplot2::ggplot(df, ggplot2::aes(day, readiness)) +
    ggplot2::geom_line(colour = "#2c6fbb") +
    ggplot2::ylim(0, 1) +
    ggplot2::labs(x = "Day", y = "On-shift readiness",
                  title = "Readiness over time",
                  subtitle = sprintf("%s model", sim$readiness_model)) +
    ggplot2::theme_minimal()
}

#' Distribution of per-provider maximum gaps
#'
#' Histogram of each provider's longest inter-exposure gap, with the readiness
#' threshold marked.
#'
#' @param sim A run `halo_sim` object.
#' @param bins Integer histogram bins.
#' @return A ggplot object.
#' @export
plot_gap_distribution <- function(sim, bins = 30) {
  .need_ggplot(); .need_run(sim)
  df <- data.frame(gap_max = sim$results_df$gap_max)
  ggplot2::ggplot(df, ggplot2::aes(gap_max)) +
    ggplot2::geom_histogram(bins = bins, fill = "#2c6fbb", colour = "white") +
    ggplot2::geom_vline(xintercept = sim$readiness_threshold_days,
                        linetype = "dashed", colour = "#c0392b") +
    ggplot2::labs(x = "Maximum gap (days)", y = "Providers",
                  title = "Maximum inter-exposure gap",
                  subtitle = sprintf("threshold = %d days",
                                     sim$readiness_threshold_days)) +
    ggplot2::theme_minimal()
}

#' Distribution of per-provider exposure counts
#'
#' @param sim A run `halo_sim` object.
#' @param bins Integer histogram bins.
#' @return A ggplot object.
#' @export
plot_exposure_histogram <- function(sim, bins = 30) {
  .need_ggplot(); .need_run(sim)
  df <- data.frame(n_events = sim$results_df$n_events)
  ggplot2::ggplot(df, ggplot2::aes(n_events)) +
    ggplot2::geom_histogram(bins = bins, fill = "#2c6fbb", colour = "white") +
    ggplot2::labs(x = "Exposures", y = "Providers",
                  title = "Exposures per provider") +
    ggplot2::theme_minimal()
}

#' Monte Carlo readiness band
#'
#' Median readiness with a percentile envelope across runs. When the ensemble
#' has a trained arm, both arms are drawn.
#'
#' @param mc A `halo_mc` object from [hsrunmc()].
#' @return A ggplot object.
#' @export
plot_mc_band <- function(mc) {
  .need_ggplot()
  df <- cbind(mc$band, arm = "baseline")
  if (!is.null(mc$band_trained)) {
    df <- rbind(df, cbind(mc$band_trained, arm = "trained"))
  }
  ggplot2::ggplot(df, ggplot2::aes(day)) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = lo, ymax = hi, fill = arm),
                         alpha = 0.2) +
    ggplot2::geom_line(ggplot2::aes(y = med, colour = arm)) +
    ggplot2::ylim(0, 1) +
    ggplot2::labs(x = "Day", y = "On-shift readiness",
                  title = "Monte Carlo readiness band",
                  subtitle = sprintf("%d runs", mc$n),
                  colour = NULL, fill = NULL) +
    ggplot2::theme_minimal()
}
