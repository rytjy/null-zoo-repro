#!/usr/bin/env bash
# Reproduce Canli (2026), "The Null Zoo", from a pinned upstream commit.
#
#   ./run.sh quick   # 2000 replications, byte-for-byte comparison   (~4.5 min)
#   ./run.sh full    # 10,000 replications, 1,999 bootstrap draws   (counts)
#
# Exit codes: 0 = all checks pass, 1 = mismatch, 2 = environment problem.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE="${1:-quick}"
PIN="9c43375064153469729d158d7a3a3534f2472c53"
UPSTREAM="https://github.com/arhancanli/null-zoo.git"
REQ_NODE="24.21.0"
WORKDIR="${NULL_ZOO_WORKDIR:-$ROOT/.work/null-zoo}"

die() { echo "FAIL: $*" >&2; exit 1; }

case "$MODE" in quick|full) ;; *) echo "usage: $0 quick|full" >&2; exit 2 ;; esac

command -v git  >/dev/null || die "git not found"
command -v node >/dev/null || die "node not found"

NODE_V="$(node -v | sed 's/^v//')"
if [ "$NODE_V" != "$REQ_NODE" ]; then
  if [ "${ALLOW_OTHER_NODE:-0}" = "1" ]; then
    echo "WARN: node $NODE_V != $REQ_NODE — byte-identity is not expected"
  else
    die "node $NODE_V != $REQ_NODE (use .nvmrc, or set ALLOW_OTHER_NODE=1)"
  fi
fi

# Shallow fetch of exactly the pinned commit; no full clone.
mkdir -p "$WORKDIR"
if [ ! -d "$WORKDIR/.git" ]; then
  git -C "$WORKDIR" init -q
  git -C "$WORKDIR" remote add origin "$UPSTREAM"
else
  git -C "$WORKDIR" remote set-url origin "$UPSTREAM"
fi
echo "== fetching $PIN"
git -C "$WORKDIR" -c http.version=HTTP/1.1 fetch --quiet --depth 1 origin "$PIN"
git -C "$WORKDIR" checkout -q --detach FETCH_HEAD 2>/dev/null || die "cannot check out $PIN"
git -C "$WORKDIR" clean -qfdx

echo "== upstream $PIN, node $NODE_V"

if [ "$MODE" = "quick" ]; then
  echo "== quick: 2000 replications"
  node "$WORKDIR/src/scripts/research/null-zoo/run.mjs" 2000 > "$WORKDIR/.repro-v0.json"
  if cmp -s "$WORKDIR/.repro-v0.json" "$WORKDIR/src/config/research/null-zoo-v0.json"; then
    echo "PASS: byte-identical to the committed src/config/research/null-zoo-v0.json"
    ( command -v sha256sum >/dev/null && sha256sum "$WORKDIR/src/config/research/null-zoo-v0.json" ) || true
  else
    echo "FAIL: output differs from the committed v0 file (see MISMATCH.md)" >&2
    exit 1
  fi
else
  echo "== full: 10000 replications x 1999 bootstrap draws"
  node "$WORKDIR/analysis/extend.mjs" 10000 1999 > "$WORKDIR/.repro-extended.json"
  node "$ROOT/verify.mjs" "$WORKDIR/.repro-extended.json" "$ROOT/expected.json"
fi
