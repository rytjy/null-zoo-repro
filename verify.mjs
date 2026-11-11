#!/usr/bin/env node
// Compare a fresh extended run against expected.json.
// Counts must match exactly; float fields are deliberately not compared.
import { readFileSync } from "node:fs";

const [producedPath, expectedPath] = process.argv.slice(2);
if (!producedPath || !expectedPath) {
  console.error("usage: node verify.mjs <produced.json> <expected.json>");
  process.exit(2);
}

const produced = JSON.parse(readFileSync(producedPath, "utf8"));
const expected = JSON.parse(readFileSync(expectedPath, "utf8"));

const problems = [];
const note = (msg) => problems.push(msg);

for (const key of ["reps", "bootstrap_draws"]) {
  if (produced[key] !== expected[key]) note(`${key}: produced ${produced[key]} != expected ${expected[key]}`);
}

for (const key of Object.keys(expected.design || {})) {
  const a = produced.design?.[key];
  const b = expected.design[key];
  if (typeof b === "number" && typeof a === "number") {
    if (Math.abs(a - b) > 1e-12) note(`design.${key}: ${a} != ${b}`);
  } else if (a !== b) {
    note(`design.${key}: ${a} != ${b}`);
  }
}

const byFamily = new Map((produced.rows || []).map((r) => [r.family, r]));
if (byFamily.size !== expected.rows.length) {
  note(`families: produced ${byFamily.size} != expected ${expected.rows.length}`);
}

let compared = 0;
for (const exp of expected.rows) {
  const got = byFamily.get(exp.family);
  if (!got) { note(`missing family ${exp.family}`); continue; }
  for (const block of ["size", "power", "correct"]) {
    for (const [validator, count] of Object.entries(exp[block])) {
      const actual = got[block]?.[validator];
      compared += 1;
      if (actual !== count) {
        note(`${exp.family}.${block}.${validator}: produced ${actual} != expected ${count}`);
      }
    }
  }
}

if (problems.length === 0) {
  console.log(`PASS: ${compared} counts match across ${expected.rows.length} families (reps=${expected.reps}, bootstrap_draws=${expected.bootstrap_draws})`);
  process.exit(0);
}

console.error(`FAIL: ${problems.length} mismatch(es) out of ${compared} compared counts`);
for (const p of problems.slice(0, 40)) console.error("  - " + p);
if (problems.length > 40) console.error(`  ... and ${problems.length - 40} more`);
console.error("\nIf counts differ, the run is not comparable to the published results.");
console.error("If only float fields differ, that is expected — see MISMATCH.md.");
process.exit(1);
