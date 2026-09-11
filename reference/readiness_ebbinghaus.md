# Ebbinghaus forgetting-curve readiness

Readiness follows the Ebbinghaus form `1 / (1 + b * days_since)`, a
slower initial decay than exponential with a heavy tail.

## Usage

``` r
readiness_ebbinghaus(days_since, b = 0.05)
```

## Arguments

- days_since:

  Numeric scalar, vector, or matrix of days since the last exposure or
  training reset.

- b:

  Numeric. Shape parameter; larger `b` decays faster.

## Value

Numeric of the same shape as `days_since`, values in (0, 1\].

## Examples

``` r
readiness_ebbinghaus(c(0, 60, 120), b = 0.05)
#> [1] 1.0000000 0.2500000 0.1428571
```
