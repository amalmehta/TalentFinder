// Checks the web Markdown export is identical to the Swift one.
// Run from the repository root: node --test web/tests/export.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { markdown, change, whole, previousTo, fileName } from "../js/export.js";

const load = (p) => JSON.parse(readFileSync(new URL(p, import.meta.url), "utf8"));
const survey = load("../data/survey.json");
const fixtures = load("./export-fixtures.json");

test("there are export fixtures to check", () => assert.ok(fixtures.length >= 4));

for (const f of fixtures) {
  test(`Markdown matches Swift exactly: ${f.name}`, () => {
    const md = markdown(f.result, survey, {
      date: f.date, previous: f.previous, previousDate: f.previousDate, activityCount: f.activityCount,
    });
    assert.equal(md, f.markdown);
  });
}

test("rounding and change markers match Swift", () => {
  assert.equal(change(2.5), "▲3");
  assert.equal(change(-2.5), "▼3");
  assert.equal(change(0.4), "–");
  assert.equal(change(-0.4), "–");
  assert.equal(whole(-0.2), 0);
  assert.ok(!Object.is(whole(-0.2), -0));
});

test("previous result and file name", () => {
  const a = { completedAt: "2026-09-01T10:00:00.000Z" }, b = { completedAt: "2026-10-01T10:00:00.000Z" };
  assert.equal(previousTo(b, [a, b]), a);
  assert.equal(previousTo(a, [a, b]), null);
  assert.match(fileName(b), /^TalentFinder Results 2026-(09-30|10-0[12])$/);
});
