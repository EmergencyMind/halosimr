# Construct a HALO simulation

Construct a HALO simulation

## Usage

``` r
halo_sim(
  schedule,
  events,
  providers = NULL,
  seed = 42,
  readiness_model = "binary",
  readiness_threshold_days = 90,
  readiness_half_life_days = 60,
  ebbinghaus_b = 0.05,
  step_partial_value = 0.5,
  step_t2_days = 180,
  training_program = "none",
  training_interval_days = 28,
  training_start_day = 0
)
```

## Arguments

- schedule:

  Character (providers x days) matrix of `"d"`/`"n"`/`"o"`, e.g. from
  [`generate_schedule()`](https://emergencymind.github.io/halosimr/reference/generate_schedule.md).

- events:

  Data frame of events with `day_idx` and `shift_type`, e.g. from
  [`generate_events()`](https://emergencymind.github.io/halosimr/reference/generate_events.md).

- providers:

  Optional character vector of provider ids (defaults to `P0001`,
  `P0002`, ...).

- seed:

  Integer seed for the warmup draw.

- readiness_model:

  One of `"binary"`, `"exponential"`, `"ebbinghaus"`, `"step"`.

- readiness_threshold_days:

  Integer threshold for `binary`/`step` and the gap exceed flag.

- readiness_half_life_days:

  Numeric half-life for `exponential`.

- ebbinghaus_b:

  Numeric shape for `ebbinghaus`.

- step_partial_value, step_t2_days:

  Partial value and second threshold for `step`.

- training_program:

  One of `"none"`, `"monthly"`, `"bimonthly"`, `"quarterly"`,
  `"custom"`.

- training_interval_days:

  Integer interval for `custom`.

- training_start_day:

  Integer 0-based day of first training.

## Value

An object of class `halo_sim`.

## Examples

``` r
sched <- generate_schedule(20, 90, "3/7 Day", seed = 1)
ev <- generate_events(90, rate = 0.2, seed = 1)
sim <- halo_sim(sched, ev, readiness_model = "exponential")
sim <- hsrun(sim)
```
