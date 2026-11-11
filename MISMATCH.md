# What counts as "reproduced"

There are two different claims in the null-zoo README, and they fail differently.

## 1. Byte-for-byte (the `quick` check)

The committed `src/config/research/null-zoo-v0.json` (5,782 bytes, sha256
`e8287f19cf25a7e0858ab12d19e2c2154f1068c5c32459123d68ec3a7cd3ce0f`) can be
regenerated exactly:

    node src/scripts/research/null-zoo/run.mjs 2000 | cmp - src/config/research/null-zoo-v0.json

On Node 24.21.0 / Linux x64 this passes with no differences at all. On a
different V8 build the JSON can differ in the last decimal digit of floating
point fields while every count stays the same. That is an environment
statement, not a content statement.

## 2. Count-identical (the `full` check)

`analysis/extend.mjs 10000 1999` regenerates the ten-thousand-replication
robustness run. Here we compare the **raw counts** — `size`, `power` and
`correct` for 11 validators across 8 families — against `expected.json`.

Observed on Node 24.21.0 / Linux x64 (2026-11-08):

- 8/8 families completed; every count matched exactly;
- `diagnostics` float fields differed at ~1e-16;
- 3 `size_adjusted.cutoff` values differed at ~1e-16.

So: counts are reproducible, last-bit floats are not guaranteed across
engines. `verify.mjs` therefore compares counts only, and says so.

## If your counts differ

Counts are integers out of `reps`. A difference means the run is not
comparable, and the usual causes are, in order:

1. wrong upstream commit (this harness pins `9c43375064153469729d158d7a3a3534f2472c53`);
2. altered seeds or a modified `analysis/extend.mjs`;
3. different `reps` / `bootstrapDraws` arguments;
4. a different family set (the script iterates over `FAMILIES` from `families.mjs`).

Check the printed `reps` / `bootstrap_draws` first; `verify.mjs` reports them.
