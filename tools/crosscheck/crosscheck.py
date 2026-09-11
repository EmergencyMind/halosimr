"""Cross-check: dump the halosim (Python) engine's deterministic outputs.

Feeds a fixed, hand-built schedule and event stream (no RNG) through the Python
engine and writes the exposure matrix, per-provider gap statistics, and the four
readiness kernels (computed with no warmup) to expected.json. crosscheck.R then
recomputes the same quantities in halosimr and asserts an exact match.

RNG-dependent stages (schedule/event generation, warmup) are deliberately
excluded: the two engines match by design on the deterministic computation, not
on random draws.

Run:  python3 crosscheck.py > expected.json
      (with the halosim package importable, e.g. PYTHONPATH=projects/halosim)
"""
import json
import numpy as np
import pandas as pd

from halosim.simulation import Simulation
from halosim.exposure import compute_exposure
from halosim.readiness import compute_readiness

N_DAYS = 20
PROVIDERS = ["P1", "P2", "P3", "P4"]
THRESHOLD = 8          # readiness threshold / step t1 / gap flag
HALF_LIFE = 6
EBB_B = 0.05
STEP_T2 = 14
STEP_PARTIAL = 0.5
MODELS = ["binary", "exponential", "ebbinghaus", "step"]


def build_inputs():
    """Deterministic schedule + events, constructed identically in R."""
    sched = np.full((4, N_DAYS), "o", dtype="U1")
    for t in range(N_DAYS):
        if t % 3 == 0:
            sched[0, t] = "d"      # P1: day shift every 3rd day
        if t % 3 == 1:
            sched[1, t] = "n"      # P2: night shift on t % 3 == 1
        if t % 2 == 0:
            sched[2, t] = "d"      # P3: day shift on even days
        # P4: always off
    events = pd.DataFrame(
        [{"day_idx": d, "shift_type": "day"} for d in (0, 6, 12, 18)]
        + [{"day_idx": d, "shift_type": "night"} for d in (1, 7, 13)]
    )
    return sched, events


def native(x):
    """Convert numpy scalars / NaN to JSON-native values."""
    if isinstance(x, (np.integer,)):
        return int(x)
    if isinstance(x, (np.floating,)):
        return None if np.isnan(x) else float(x)
    if isinstance(x, (np.bool_,)):
        return bool(x)
    if x is None or (isinstance(x, float) and np.isnan(x)):
        return None
    return x


def main():
    sched, events = build_inputs()
    sim = Simulation(
        n_days=N_DAYS, providers=list(PROVIDERS), schedule=sched, events=events,
        readiness_model="binary", readiness_threshold_days=THRESHOLD,
        readiness_half_life_days=HALF_LIFE, ebbinghaus_b=EBB_B,
        step_partial_value=STEP_PARTIAL, step_t2_days=STEP_T2,
    )

    exposure_matrix, results_df = compute_exposure(sim)

    # Readiness with no warmup, combined = exposure (no training), per model.
    sim.combined_matrix = exposure_matrix
    readiness = {}
    for m in MODELS:
        sim.readiness_model = m
        r = compute_readiness(sim, initial_last=None)
        readiness[m] = r.tolist()

    results = [
        {k: native(v) for k, v in rec.items()}
        for rec in results_df.to_dict(orient="records")
    ]

    out = {
        "n_days": N_DAYS,
        "providers": PROVIDERS,
        "threshold": THRESHOLD,
        "half_life": HALF_LIFE,
        "ebb_b": EBB_B,
        "step_t2": STEP_T2,
        "step_partial": STEP_PARTIAL,
        "exposure": exposure_matrix.astype(int).tolist(),
        "results": results,
        "readiness": readiness,
    }
    print(json.dumps(out, indent=2))


if __name__ == "__main__":
    main()
