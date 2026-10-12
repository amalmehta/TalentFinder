// Markdown export for the web version. A port of Sources/TalentFinderCore/ResultExport.swift;
// tests/export.test.mjs checks the output is identical. Dates arrive already formatted.

export const SITE_URL = "https://amalmehta.github.io/TalentFinder/";

/** Rounds half away from zero, like Swift's rounded(). */
export const whole = (x) => {
  const n = Math.sign(x) * Math.round(Math.abs(x));
  return n === 0 ? 0 : n; // no "-0"
};

export function change(d) {
  const n = whole(d);
  return n > 0 ? `▲${n}` : n < 0 ? `▼${-n}` : "–";
}

const cell = (s) => String(s).replaceAll("|", "\\|");

/**
 * @param {object} r the result
 * @param {object} survey data/survey.json (for aptitude names and summaries)
 * @param {{date: string, previous?: object|null, previousDate?: string|null, activityCount: number}} opts
 */
export function markdown(r, survey, { date, previous = null, previousDate = null, activityCount }) {
  const apt = Object.fromEntries(survey.aptitudes.map((a) => [a.id, a]));
  const scoreIn = (res, id) => res.scores.find((s) => s.aptitude === id)?.score ?? 0;
  const lines = ["# TalentFinder results", "", `Completed ${date} · based on ${r.answeredCount} answers`, ""];

  lines.push("## Your aptitudes", "");
  if (previous && previousDate) {
    lines.push(`| Aptitude | Score | Change since ${cell(previousDate)} |`, "|---|---:|---:|");
    for (const s of r.scores) {
      lines.push(`| ${cell(apt[s.aptitude].name)} | ${whole(s.score)} | ${change(s.score - scoreIn(previous, s.aptitude))} |`);
    }
  } else {
    lines.push("| Aptitude | Score |", "|---|---:|");
    for (const s of r.scores) lines.push(`| ${cell(apt[s.aptitude].name)} | ${whole(s.score)} |`);
  }
  lines.push("");

  lines.push("## Your top strengths", "");
  r.scores.slice(0, 3).forEach((s, i) => {
    lines.push(`### ${i + 1}. ${apt[s.aptitude].name} — ${whole(s.score)}`, "", apt[s.aptitude].summary, "");
    if (s.evidence.length) lines.push(...s.evidence.map((e) => `- ${e}`), "");
  });

  lines.push("## Activities that suit you", "", "| Activity | Category | Fit | Why |", "|---|---|---:|---|");
  for (const m of r.matches.slice(0, activityCount)) {
    lines.push(`| ${cell(m.activity)} | ${cell(m.category)} | ${whole(m.fit)}% | ${cell(m.reasons.map((d) => apt[d].name).join(", "))} |`);
  }
  lines.push("", "_Fit is a weighted average of the aptitudes each activity draws on. It's a pointer for what to try, not a verdict._",
    "", "---", "", `Made with [TalentFinder](${SITE_URL})`, "");
  return lines.join("\n");
}

/** e.g. "TalentFinder Results 2026-10-11", in the reader's time zone. */
export function fileName(r) {
  const d = new Date(r.completedAt);
  const pad = (n) => String(n).padStart(2, "0");
  return `TalentFinder Results ${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

/** The result completed just before `result` in a history kept oldest first. */
export function previousTo(result, history) {
  return history.filter((r) => r.completedAt < result.completedAt).at(-1) ?? null;
}
