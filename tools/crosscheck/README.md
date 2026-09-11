# Engine cross-check (Python halosim vs R halosimr)

Proves that `halosimr` reproduces the original Python `halosim` engine on the
**deterministic** computation: given identical inputs, both must produce the
same exposure matrix, per-provider gap statistics, and readiness kernels.

RNG-dependent stages (schedule/event generation, warmup) are deliberately
excluded. Those match by distribution, not value, so the check feeds a fixed,
hand-built schedule and event stream through both engines and compares the
stages that do not depend on random draws.

## Run

```bash
# from this directory; needs Python halosim importable and R halosimr + jsonlite installed
HALOSIM_DIR=/path/to/halosim R_LIBS=/path/to/rlibs ./run.sh
```

`run.sh` runs `crosscheck.py` (dumps `expected.json` from the Python engine),
then `crosscheck.R` (recomputes in halosimr and asserts an exact match). It
exits non-zero on any mismatch.

## Files

- `crosscheck.py` - builds the fixed inputs, runs the Python engine, writes `expected.json`
- `crosscheck.R` - rebuilds the same inputs, runs halosimr, compares every stage
- `run.sh` - runs both in order
- `expected.json` - generated, not committed

## What it verifies

- exposure matrix (shift-matched join)
- gap statistics: `n_events`, `t2first`, min / Q25 / median / mean / Q75 / max, exceeds-threshold flag
- readiness kernels: `binary`, `exponential`, `ebbinghaus`, `step`
