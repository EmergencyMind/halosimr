# Run a Monte Carlo ensemble of HALO simulations

Run a Monte Carlo ensemble of HALO simulations

## Usage

``` r
hsrunmc(
  n,
  schedule_fn,
  events_fn,
  training_program = "none",
  providers = NULL,
  probs = c(0.1, 0.5, 0.9),
  seeds = NULL,
  ...
)
```

## Arguments

- n:

  Integer number of runs.

- schedule_fn:

  Function of one argument (a seed) returning a schedule matrix, e.g.
  `function(s) generate_schedule(200, 365, "3/7 Day", seed = s)`.

- events_fn:

  Function of one argument (a seed) returning an events data frame, e.g.
  `function(s) generate_events(365, rate = 0.1, seed = s)`.

- training_program:

  Program for the trained arm. `"none"` runs the baseline only (no
  lift).

- providers:

  Optional provider ids passed to
  [`halo_sim()`](https://emergencymind.github.io/halosimr/reference/halo_sim.md).

- probs:

  Length-3 numeric of lower/median/upper quantiles for the band.

- seeds:

  Optional integer vector of length `n`; defaults to `1:n`.

- ...:

  Further arguments passed to
  [`halo_sim()`](https://emergencymind.github.io/halosimr/reference/halo_sim.md)
  (readiness model and parameters, `training_interval_days`, etc.).

## Value

An object of class `halo_mc` with the per-run readiness matrices, the
baseline band (and trained band + `lift` when a program is set), stored
per-run `gap_max`, and a per-run `summary` data frame.

## Examples

``` r
mc <- hsrunmc(
  n = 10,
  schedule_fn = function(s) generate_schedule(100, 180, "3/7 Day", seed = s),
  events_fn   = function(s) generate_events(180, rate = 0.15, seed = s),
  readiness_model = "exponential", training_program = "monthly"
)
mc
#> <halo_mc>  10 runs x 180 days
#>   training: monthly
#>   baseline median readiness: 0.758
#>   trained median readiness:  0.826  (mean lift +0.068)
```
