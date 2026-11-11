# null-zoo-repro

Independent reproduction harness for **Canli (2026), *The Null Zoo*** — a
size-and-power study of backtest-overfitting corrections on synthetic searches
with known ground truth (DOI [10.5281/zenodo.23018988](https://doi.org/10.5281/zenodo.23018988), code MIT).

This repository contains no research code. It pins the upstream commit,
checks the Node version, runs two commands, and tells you whether the numbers
came out the same.

## What it checks

| Mode | Command | Claim tested | Expected |
|---|---|---|---|
| `quick` | `run.mjs 2000` | the published v0 result | **byte-identical** to the committed JSON |
| `full` | `extend.mjs 10000 1999` | the 10,000-replication robustness run | **all 264 counts** identical (8 families × 11 validators × size/power/correct) |

`quick` is the strict one and takes about 4.5 minutes (measured: 4m24s on Node
24.21.0, Linux x64, one core). `full` is the expensive one and compares
integers, not floats — see [MISMATCH.md](MISMATCH.md) for why that distinction
matters.

## Run it

    git clone <this repo> null-zoo-repro && cd null-zoo-repro
    nvm use                 # .nvmrc pins Node 24.21.0
    ./run.sh quick          # byte comparison
    ./run.sh full           # 10,000 replications; compares every count

Pinned upstream: `arhancanli/null-zoo@9c43375064153469729d158d7a3a3534f2472c53`
(package version 1.0.0).

Requirements: git, Node 24.21.0 (exact — the byte comparison is a property of
one V8 build; `ALLOW_OTHER_NODE=1` downgrades the check to a warning).

Exit codes: `0` pass, `1` mismatch, `2` environment problem.

## Headline numbers you should get back

From `expected.json` (raw counts out of 10,000 replications; the paper reports
the same rates):

| Family | Validator | size | power | correct |
|---|---|---|---|---|
| iid_normal | luck_trials | 516 | 5303 | 5022 |
| iid_normal | deflated_sharpe | 2 | 952 | 951 |
| ar1 | luck_trials | 1965 | 5981 | 4755 |
| ar1 | bootstrap_best | 1879 | 5793 | 4629 |

Rate form: `ar1.luck_trials` size = 19.65%, matching the paper's 19.65.

## What this does *not* claim

- It does not re-derive the paper's method; it reruns the authors' code at a
  pinned commit.
- It does not claim byte-identity on other V8 builds, platforms, or Node
  versions.
- It does not check the paper's prose, only the numbers its code produces.

## Layout

    run.sh            entry point (clone/pin/run/compare)
    verify.mjs        count comparison for the full run
    expected.json     pinned commit, design, v0 hash, 264 raw counts
    MISMATCH.md       byte-level vs count-level, and what a mismatch means
    .github/workflows/repro.yml   CI: quick on push, full on demand
