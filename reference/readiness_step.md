# Two-threshold step readiness

Readiness is 1 up to `t1` days, a `partial` value between `t1` and `t2`,
and 0 beyond `t2`.

## Usage

``` r
readiness_step(days_since, t1 = 90, t2 = 180, partial = 0.5)
```

## Arguments

- days_since:

  Numeric scalar, vector, or matrix of days since the last exposure or
  training reset.

- t1:

  Integer. Days of full readiness.

- t2:

  Integer. Days at which partial readiness ends.

- partial:

  Numeric between 0 and 1. Readiness value on the `t1`..`t2` interval.

## Value

Numeric of the same shape as `days_since`: 0, the partial value, or 1.

## Examples

``` r
readiness_step(c(0, 90, 150, 200), t1 = 90, t2 = 180, partial = 0.5)
#> [1] 1.0 1.0 0.5 0.0
```
