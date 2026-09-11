# Generate a provider schedule matrix

Each provider receives an independently randomised schedule satisfying
the chosen type. Seeding is applied once at the population level so
results are reproducible for a given set of inputs.

## Usage

``` r
generate_schedule(
  n_providers,
  n_days,
  schedule_type = DEFAULT_SCHEDULE_TYPE,
  seed = 42,
  weights = NULL
)
```

## Arguments

- n_providers:

  Integer number of providers (capped at 5000).

- n_days:

  Integer window length in days.

- schedule_type:

  One of `"3/7 Day"`, `"3/7 Night"`, `"4/7 Day"`, `"4/7 Night"`,
  `"Progressive (day & night mix)"`, `"Random"`. The `"Random"` type
  draws each day from the paper's empirical weights (d = 0.246, n =
  0.230, o = 0.524); pass `weights` to override, e.g.
  `c(d = 1/3, n = 1/3, o = 1/3)` for an equal split.

- seed:

  Integer RNG seed.

- weights:

  Optional named numeric with elements `d`, `n`, `o`. When supplied,
  every provider-day is drawn from these probabilities and
  `schedule_type` is ignored.

## Value

A character (providers x days) matrix of `"d"`/`"n"`/`"o"`.

## Examples

``` r
sched <- generate_schedule(10, 28, "3/7 Day", seed = 1)
table(sched)
#> sched
#>   d   o 
#> 120 160 
```
