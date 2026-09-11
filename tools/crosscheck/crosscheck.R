# Cross-check: recompute the Python engine's deterministic outputs in halosimr
# and assert an exact match. Reads expected.json (from crosscheck.py), rebuilds
# the same fixed inputs, and compares the exposure matrix, per-provider gap
# statistics, and the four readiness kernels (no warmup).
#
# Run:  Rscript crosscheck.R expected.json
# Exits non-zero on any mismatch.

args <- commandArgs(trailingOnly = TRUE)
json_path <- if (length(args)) args[1] else "expected.json"

suppressPackageStartupMessages({
  library(halosimr)
  library(jsonlite)
})

exp <- jsonlite::fromJSON(json_path, simplifyMatrix = TRUE)
N_DAYS    <- exp$n_days
PROVIDERS <- exp$providers
THRESHOLD <- exp$threshold

# --- rebuild the identical inputs (mirror of build_inputs in crosscheck.py) ---
sched <- matrix("o", nrow = 4, ncol = N_DAYS)
for (t in 0:(N_DAYS - 1)) {
  j <- t + 1L
  if (t %% 3 == 0) sched[1, j] <- "d"
  if (t %% 3 == 1) sched[2, j] <- "n"
  if (t %% 2 == 0) sched[3, j] <- "d"
}
events <- data.frame(
  day_idx = c(0L, 6L, 12L, 18L, 1L, 7L, 13L),
  shift_type = c(rep("day", 4), rep("night", 3)),
  stringsAsFactors = FALSE
)

sim <- list(schedule = sched, events = events, providers = PROVIDERS,
            readiness_threshold_days = THRESHOLD,
            readiness_half_life_days = exp$half_life, ebbinghaus_b = exp$ebb_b,
            step_t2_days = exp$step_t2, step_partial_value = exp$step_partial)

# ---------------------------------------------------------------------------
fails <- 0L
report <- function(label, ok) {
  cat(sprintf("%-40s %s\n", label, if (isTRUE(ok)) "MATCH" else "MISMATCH"))
  if (!isTRUE(ok)) fails <<- fails + 1L
}

# --- exposure matrix ---
res <- halosimr:::compute_exposure(sim)
exposure_r <- matrix(as.integer(res$exposure_matrix), nrow = nrow(res$exposure_matrix))
report("exposure matrix", identical(exposure_r, matrix(as.integer(exp$exposure),
                                                       nrow = nrow(exp$exposure))))

# --- per-provider gap statistics ---
rdf <- res$results_df
er  <- exp$results
num_cols <- c("n_events", "gap_min", "gap_q25", "gap_median", "gap_mean",
              "gap_q75", "gap_max")
gaps_ok <- all(vapply(num_cols, function(cn)
  isTRUE(all.equal(as.numeric(rdf[[cn]]), as.numeric(er[[cn]]), tolerance = 1e-9)),
  logical(1)))
report("gap statistics (numeric)", gaps_ok)

# t2first: Python null -> NA; compare with NAs aligned
t2_ok <- identical(is.na(rdf$t2first), is.na(er$t2first)) &&
  isTRUE(all.equal(rdf$t2first[!is.na(rdf$t2first)],
                   as.integer(er$t2first[!is.na(er$t2first)])))
report("gap time-to-first (t2first)", t2_ok)

flag_ok <- identical(as.logical(rdf$max_gap_exceeds_threshold),
                     as.logical(er$max_gap_exceeds_threshold))
report("gap exceeds-threshold flag", flag_ok)

# --- readiness kernels (no warmup, combined = exposure) ---
sim$combined_matrix <- res$exposure_matrix
for (m in c("binary", "exponential", "ebbinghaus", "step")) {
  sim$readiness_model <- m
  r_r <- halosimr:::compute_readiness(sim, initial_last = NULL)
  r_py <- matrix(as.numeric(exp$readiness[[m]]), nrow = nrow(exp$readiness[[m]]))
  report(sprintf("readiness: %s", m),
         isTRUE(all.equal(unname(r_r), unname(r_py), tolerance = 1e-9)))
}

cat("\n")
if (fails == 0L) {
  cat("ALL STAGES MATCH: halosimr reproduces the halosim engine exactly.\n")
} else {
  cat(sprintf("%d STAGE(S) MISMATCHED.\n", fails))
  quit(status = 1)
}
