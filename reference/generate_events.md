# Generate a Poisson HALO event stream

Generate a Poisson HALO event stream

## Usage

``` r
generate_events(
  n_days,
  rate,
  seed = 42,
  day_rate = NULL,
  night_rate = NULL,
  start_date = "2024-01-01"
)
```

## Arguments

- n_days:

  Integer window length.

- rate:

  Numeric events per day, split 50/50 day/night. Ignored when both
  `day_rate` and `night_rate` are supplied.

- seed:

  Integer RNG seed.

- day_rate, night_rate:

  Optional numeric per-day rates for each shift. Supply both to override
  `rate`.

- start_date:

  Character or Date; day 0 of the window.

## Value

A data frame with columns `day_idx` (integer, 0-based), `date` (Date),
and `shift_type` (`"day"`/`"night"`), sorted by day.

## Examples

``` r
ev <- generate_events(365, rate = 0.1, seed = 1)
nrow(ev)
#> [1] 35
```
