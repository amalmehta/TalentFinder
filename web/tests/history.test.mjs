// Run from the repository root: node --test web/tests/history.test.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { score } from "../js/scoring.js";
import { adding, removing, scoreFor, latestChange, migrate } from "../js/history.js";

const survey = JSON.parse(readFileSync(new URL("../data/survey.json", import.meta.url), "utf8"));
const fixtures = JSON.parse(readFileSync(new URL("./fixtures.json", import.meta.url), "utf8"));
const at = (name, iso) => ({ completedAt: iso, ...score(fixtures.find((f) => f.name === name).answers, survey) });
const nature = at("favor nature", "2026-10-01T10:00:00.000Z");
const musical = at("favor musical", "2026-10-05T10:00:00.000Z");
const aptitudes = survey.aptitudes.map((a) => a.id);

test("adding keeps oldest first and replaces a result with the same time", () => {
  let h = adding(musical, []);
  h = adding(nature, h);
  assert.deepEqual(h.map((r) => r.completedAt), [nature.completedAt, musical.completedAt]);
  assert.equal(adding(nature, h).length, 2);
});

test("removing", () => {
  assert.deepEqual(removing(nature.completedAt, [nature, musical]), [musical]);
});

test("latest change", () => {
  const c = latestChange([nature, musical], aptitudes);
  assert.ok(c.musical > 0);
  assert.ok(c.nature < 0);
  assert.equal(c.musical, scoreFor(musical, "musical") - scoreFor(nature, "musical"));
  assert.equal(latestChange([nature], aptitudes), null);
});

test("migrates the single result saved by earlier versions", () => {
  assert.deepEqual(migrate(null, nature), [nature]);
  assert.deepEqual(migrate(null, null), []);
  assert.deepEqual(migrate([musical, nature], nature), [nature, musical]);
});
