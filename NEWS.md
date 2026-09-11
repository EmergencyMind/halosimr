# halosimr 0.1.0

First public release. An R implementation of the HALO event exposure and
readiness/training simulation, extending the methodology of the Code Blue
Blindspots paper (PMID 41633464).

* Single-run engine: `halo_sim()` and `hsrun()`.
* Monte Carlo ensembles with baseline vs training lift: `hsrunmc()`.
* Input generators: `generate_schedule()`, `schedule_from_pattern()`,
  `generate_events()`, plus CSV / data-frame ingest via `load_schedule()` and
  `load_events()`.
* Four readiness models: `readiness_binary()`, `readiness_exponential()`,
  `readiness_ebbinghaus()`, `readiness_step()`.
* Scheduled training programs: monthly, bimonthly, quarterly, custom.
* Figures: `plot_readiness()`, `plot_gap_distribution()`,
  `plot_exposure_histogram()`, `plot_mc_band()`.
* Report template (`inst/report_template.Rmd`) and a getting-started vignette.
* Zero hard dependencies (base R only; ggplot2 optional for plots).
* Verified to reproduce the Python halosim engine on the deterministic
  computation (exposure, gap statistics, readiness kernels).
