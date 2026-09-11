# Load HALO events from a data frame or CSV file

Required columns: `date` (YYYY-MM-DD) and `shift_type`
(`"day"`/`"night"`). Events outside the window are dropped with a
warning.

## Usage

``` r
load_events(x, n_days, start_date = "2024-01-01")
```

## Arguments

- x:

  A data frame, or a path to a CSV file, with the required columns.

- n_days:

  Integer window length.

- start_date:

  Character or Date; day 0 of the window.

## Value

A data frame with columns `day_idx`, `date`, `shift_type`.
