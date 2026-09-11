# Exponential readiness decay

Readiness decays exponentially with a fixed half-life: it halves every
`half_life` days since the last reset. Rate is `log(2) / half_life`.

## Usage

``` r
readiness_exponential(days_since, half_life = 60)
```

## Arguments

- days_since:

  Numeric scalar, vector, or matrix of days since the last exposure or
  training reset.

- half_life:

  Numeric. Days for readiness to halve. Values below 1 are treated as 1.

## Value

Numeric of the same shape as `days_since`, values in (0, 1\].

## Examples

``` r
readiness_exponential(c(0, 60, 120), half_life = 60)
#> [1] 1.00 0.50 0.25
```
