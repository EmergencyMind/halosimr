# Run a HALO simulation

Executes the pipeline: on-shift mask -\> exposure + gap stats -\> warmup
-\> training -\> combined -\> readiness -\> daily aggregates.

## Usage

``` r
hsrun(sim)
```

## Arguments

- sim:

  A `halo_sim` object from
  [`halo_sim()`](https://emergencymind.github.io/halosimr/reference/halo_sim.md).

## Value

The `halo_sim` object with output fields attached: `exposure_matrix`,
`results_df`, `training_matrix`, `combined_matrix`, `readiness_matrix`,
`proportion_ready_on_shift`, `proportion_ready_all`.
