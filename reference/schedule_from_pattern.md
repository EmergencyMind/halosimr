# Build schedules by tiling a 28-day pattern

Repeats a 28-character d/n/o template across the window. Every provider
gets the same schedule. Shorter patterns are padded with `"o"`; longer
ones are truncated to 28.

## Usage

``` r
schedule_from_pattern(n_providers, n_days, pattern)
```

## Arguments

- n_providers:

  Integer number of providers (capped at 5000).

- n_days:

  Integer window length.

- pattern:

  Character scalar of d/n/o characters (up to 28 used).

## Value

A character (providers x days) matrix.

## Examples

``` r
schedule_from_pattern(3, 56, "dddoooonnnooooo")[1, 1:14]
#>  [1] "d" "d" "d" "o" "o" "o" "o" "n" "n" "n" "o" "o" "o" "o"
```
