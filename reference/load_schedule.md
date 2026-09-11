# Load a schedule from a data frame or CSV file

Required columns: `provider_id`, `date` (YYYY-MM-DD), `shift_type` (one
of d/day/n/night/o/off). Provider-days missing from the input default to
`"o"`.

## Usage

``` r
load_schedule(x, n_days, start_date = "2024-01-01")
```

## Arguments

- x:

  A data frame, or a path to a CSV file, with the required columns.

- n_days:

  Integer window length.

- start_date:

  Character or Date; day 0 of the window.

## Value

A list with `schedule` (character providers x days matrix) and
`providers` (character vector of ids, sorted).
