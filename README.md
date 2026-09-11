# halosimr

<!-- badges: start -->
[![R-CMD-check](https://github.com/EmergencyMind/halosimr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/EmergencyMind/halosimr/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

Simulate exposure to high-acuity, low-occurrence (HALO) events across a provider
population, model how readiness decays between exposures, and estimate how
training programs change it. An R implementation extending the methodology of
the Code Blue Blindspots paper (PMID 41633464).

## Installation

```r
# install.packages("remotes")
remotes::install_github("EmergencyMind/halosimr")
```

Plotting uses ggplot2, which is optional:

```r
install.packages("ggplot2")
```

## Quick start

```r
library(halosimr)

# 1. Generate a schedule and a stream of HALO events
sched <- generate_schedule(n_providers = 200, n_days = 365,
                           schedule_type = "3/7 Day", seed = 42)
ev    <- generate_events(n_days = 365, rate = 0.1, seed = 42)

# 2. Run one simulation
sim <- halo_sim(sched, ev, readiness_model = "exponential",
                readiness_half_life_days = 60)
sim <- hsrun(sim)
sim

plot_readiness(sim)
plot_gap_distribution(sim)
```

Repeat over many random draws to see the spread, and compare a training program
against baseline:

```r
mc <- hsrunmc(
  n = 50,
  schedule_fn = function(s) generate_schedule(200, 365, "3/7 Day", seed = s),
  events_fn   = function(s) generate_events(365, rate = 0.1, seed = s),
  readiness_model = "exponential", readiness_half_life_days = 60,
  training_program = "monthly"
)
mc
plot_mc_band(mc)
```

## Readiness models

Four decay models map days since the last exposure or training reset to a
readiness value in the range 0 to 1:

- `binary`: ready within a threshold, otherwise not
- `exponential`: halves every `readiness_half_life_days`
- `ebbinghaus`: forgetting curve `1 / (1 + b * days)`
- `step`: full, then partial, then zero across two thresholds

## Documentation

```r
vignette("halosimr")
```

## License

MIT (c) Daniel Dworkis. See `LICENSE`.
