# Binary readiness

Readiness is 1 while days since the last reset is at or below
`threshold`, and 0 afterwards. This is the basic model.

## Usage

``` r
readiness_binary(days_since, threshold = 90)
```

## Arguments

- days_since:

  Numeric scalar, vector, or matrix of days since the last exposure or
  training reset.

- threshold:

  Integer. Days a provider stays ready after a reset.

## Value

Numeric of the same shape as `days_since`, either 0 or 1.

## Examples

``` r
readiness_binary(c(0, 45, 90, 120), threshold = 90)
#> [1] 1 1 1 0
```
