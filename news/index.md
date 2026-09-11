# Changelog

## halosimr 0.1.0

First public release. An R implementation of the HALO event exposure and
readiness/training simulation, extending the methodology of the Code
Blue Blindspots paper (PMID 41633464).

- Single-run engine:
  [`halo_sim()`](https://emergencymind.github.io/halosimr/reference/halo_sim.md)
  and
  [`hsrun()`](https://emergencymind.github.io/halosimr/reference/hsrun.md).
- Monte Carlo ensembles with baseline vs training lift:
  [`hsrunmc()`](https://emergencymind.github.io/halosimr/reference/hsrunmc.md).
- Input generators:
  [`generate_schedule()`](https://emergencymind.github.io/halosimr/reference/generate_schedule.md),
  [`schedule_from_pattern()`](https://emergencymind.github.io/halosimr/reference/schedule_from_pattern.md),
  [`generate_events()`](https://emergencymind.github.io/halosimr/reference/generate_events.md),
  plus CSV / data-frame ingest via
  [`load_schedule()`](https://emergencymind.github.io/halosimr/reference/load_schedule.md)
  and
  [`load_events()`](https://emergencymind.github.io/halosimr/reference/load_events.md).
- Four readiness models:
  [`readiness_binary()`](https://emergencymind.github.io/halosimr/reference/readiness_binary.md),
  [`readiness_exponential()`](https://emergencymind.github.io/halosimr/reference/readiness_exponential.md),
  [`readiness_ebbinghaus()`](https://emergencymind.github.io/halosimr/reference/readiness_ebbinghaus.md),
  [`readiness_step()`](https://emergencymind.github.io/halosimr/reference/readiness_step.md).
- Scheduled training programs: monthly, bimonthly, quarterly, custom.
- Figures:
  [`plot_readiness()`](https://emergencymind.github.io/halosimr/reference/plot_readiness.md),
  [`plot_gap_distribution()`](https://emergencymind.github.io/halosimr/reference/plot_gap_distribution.md),
  [`plot_exposure_histogram()`](https://emergencymind.github.io/halosimr/reference/plot_exposure_histogram.md),
  [`plot_mc_band()`](https://emergencymind.github.io/halosimr/reference/plot_mc_band.md).
- Report template (`inst/report_template.Rmd`) and a getting-started
  vignette.
- Zero hard dependencies (base R only; ggplot2 optional for plots).
- Verified to reproduce the Python halosim engine on the deterministic
  computation (exposure, gap statistics, readiness kernels).
