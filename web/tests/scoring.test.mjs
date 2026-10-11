// Checks the JavaScript scorer gives exactly the same results as the Swift one.
// Run from the repository root: node --test web/tests
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { score, newProgress, isComplete, accepts } from "../js/scoring.js";

const load = (p) => JSON.parse(readFileSync(new URL(p, import.meta.url), "utf8"));
const survey = load("../data/survey.json");
const fixtures = load("./fixtures.json");

test("survey data has 60 questions and 10 aptitudes", () => {
  assert.equal(survey.questions.length, 60);
  assert.equal(survey.aptitudes.length, 10);
  assert.equal(new Set(survey.questions.map((q) => q.id)).size, 60);
});

test("there are parity fixtures to check", () => {
  assert.ok(fixtures.length >= 20);
});

for (const f of fixtures) {
  test(`matches Swift exactly: ${f.name}`, () => {
    const r = score(f.answers, survey);
    assert.equal(r.answeredCount, f.answeredCount);
    assert.deepEqual(r.scores, f.scores);
    assert.deepEqual(r.matches, f.matches);
  });
}

test("rejects non-integer and out-of-range answers", () => {
  const scale = survey.questions.find((q) => q.kind !== "choice");
  const choice = survey.questions.find((q) => q.kind === "choice");
  assert.equal(accepts(scale, 3), true);
  assert.equal(accepts(scale, 6), false);
  assert.equal(accepts(scale, 2.5), false);
  assert.equal(accepts(choice, 3), true);
  assert.equal(accepts(choice, 4), false);
});

test("a shuffled survey still covers every question once", () => {
  const p = newProgress(survey, true);
  assert.deepEqual([...p.order].sort(), survey.questions.map((q) => q.id).sort());
  assert.equal(isComplete(p), false);
  for (const id of p.order) p.answers[id] = 1;
  assert.equal(isComplete(p), true);
});
