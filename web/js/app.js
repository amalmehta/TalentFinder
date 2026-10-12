// TalentFinder for the web: the same survey, scoring and screens as the Mac app.
// State lives in localStorage; nothing is sent anywhere.
import { score, accepts, newProgress, isComplete } from "./scoring.js";
import { adding, removing, latestChange, migrate } from "./history.js";
import { markdown, fileName, previousTo, whole, SITE_URL } from "./export.js";

const REPO_ISSUES = "https://github.com/amalmehta/TalentFinder/issues/new";

/** Colours and icons per aptitude, matching the Mac app. */
const LOOK = {
  analytical: { color: "#2f7cf6", emoji: "🧮" },
  verbal: { color: "#5e5ce6", emoji: "📖" },
  spatial: { color: "#30b0c7", emoji: "🧊" },
  musical: { color: "#ff375f", emoji: "🎵" },
  physical: { color: "#ff9f0a", emoji: "🏃" },
  social: { color: "#ff453a", emoji: "🤝" },
  leadership: { color: "#bf5af2", emoji: "📣" },
  creative: { color: "#e6b800", emoji: "🎨" },
  handsOn: { color: "#a2845e", emoji: "🔧" },
  nature: { color: "#30d158", emoji: "🌿" },
};

// ---------- Storage (all reads and writes are guarded: storage can be blocked) ----------

// `result` is only read once, to move a result saved by earlier versions into the history.
const KEYS = { progress: "talentfinder.progress", history: "talentfinder.history", result: "talentfinder.result", settings: "talentfinder.settings" };
const DEFAULT_SETTINGS = { shuffle: true, autoAdvance: true, topCount: 10 };

function load(key) {
  try { return JSON.parse(localStorage.getItem(key)); } catch { return null; }
}
function save(key, value) {
  try {
    if (value == null) localStorage.removeItem(key);
    else localStorage.setItem(key, JSON.stringify(value));
  } catch { /* private mode or blocked storage: keep working in memory */ }
}

// ---------- State ----------

const state = {
  survey: null,
  byId: {},
  screen: "welcome",
  progress: load(KEYS.progress),
  history: migrate(load(KEYS.history), load(KEYS.result)), // oldest first
  viewingId: null, // completedAt of the past result being shown; null means the latest
  trendAptitudes: null, // aptitudes drawn on the trend chart; null until first chosen
  settings: { ...DEFAULT_SETTINGS, ...(load(KEYS.settings) ?? {}) },
  category: "All",
};

const app = document.getElementById("app");
const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
const aptitude = (id) => state.survey.aptitudes.find((a) => a.id === id);
const latest = () => state.history[state.history.length - 1] ?? null;
const shownResult = () => state.history.find((r) => r.completedAt === state.viewingId) ?? latest();
const isViewingLatest = () => shownResult() === latest();
const formatDate = (iso, opts = { dateStyle: "long", timeStyle: "short" }) => new Date(iso).toLocaleString(undefined, opts);

function show(screen) {
  state.screen = screen;
  render();
  window.scrollTo(0, 0);
  app.focus({ preventScroll: true });
}

function render() {
  if (state.screen === "survey" && !state.progress) state.screen = "welcome";
  if ((state.screen === "results" || state.screen === "history") && !state.history.length) state.screen = "welcome";
  document.title = { welcome: "TalentFinder", survey: "Survey · TalentFinder", results: "Your Results · TalentFinder", history: "Past Results · TalentFinder" }[state.screen];
  document.getElementById("history-button").hidden = !state.history.length || state.screen === "history";
  ({ welcome: renderWelcome, survey: renderSurvey, results: renderResults, history: renderHistory })[state.screen]();
}

// ---------- Survey actions ----------

function startNew() {
  state.progress = newProgress(state.survey, state.settings.shuffle);
  save(KEYS.progress, state.progress);
  show("survey");
}

function currentQuestion() {
  const p = state.progress;
  return p ? state.byId[p.order[p.currentIndex]] : null;
}

function answer(value) {
  const p = state.progress, q = currentQuestion();
  if (!q || !accepts(q, value)) return;
  p.answers[q.id] = value;
  if (state.settings.autoAdvance && p.currentIndex < p.order.length - 1) p.currentIndex += 1;
  save(KEYS.progress, p);
  renderSurvey();
}

function move(delta) {
  const p = state.progress;
  const i = p.currentIndex + delta;
  if (i < 0 || i >= p.order.length) return;
  p.currentIndex = i;
  save(KEYS.progress, p);
  renderSurvey();
}

function goToFirstUnanswered() {
  const p = state.progress;
  const i = p.order.findIndex((id) => p.answers[id] === undefined);
  if (i >= 0) { p.currentIndex = i; save(KEYS.progress, p); renderSurvey(); }
}

function finish() {
  if (!state.progress || !isComplete(state.progress)) return;
  const result = { completedAt: new Date().toISOString(), ...score(state.progress.answers, state.survey) };
  state.history = adding(result, state.history);
  state.viewingId = null;
  state.progress = null;
  save(KEYS.history, state.history);
  save(KEYS.progress, null);
  show("results");
}

function resetAll() {
  state.progress = null;
  state.history = [];
  state.viewingId = null;
  save(KEYS.progress, null);
  save(KEYS.history, null);
  save(KEYS.result, null);
  show("welcome");
}

// ---------- History actions ----------

function showLatest() {
  state.viewingId = null;
  show("results");
}

function openResult(id) {
  state.viewingId = id;
  show("results");
}

function deleteResult(id) {
  const r = state.history.find((x) => x.completedAt === id);
  if (!r) return;
  confirmThen(
    "Delete this result?",
    `The result from ${formatDate(id)} will be removed. This can't be undone.`,
    () => {
      state.history = removing(id, state.history);
      if (state.viewingId === id) state.viewingId = null;
      save(KEYS.history, state.history.length ? state.history : null);
      render();
    },
  );
}

// ---------- Screens ----------

function renderWelcome() {
  const p = state.progress;
  const tiles = state.survey.aptitudes.map((a) => `
    <div class="aptitude-tile" style="--c:${LOOK[a.id].color}">
      <span class="emoji" aria-hidden="true">${LOOK[a.id].emoji}</span>${esc(a.name)}
    </div>`).join("");
  const answered = p ? Object.keys(p.answers).length : 0;
  app.innerHTML = `
    <section class="welcome">
      <div>
        <div class="hero-icon" aria-hidden="true">✦</div>
        <h1>TalentFinder</h1>
      </div>
      <p class="lede">Find out what you're naturally good at. Answer ${state.survey.questions.length} quick questions about what you enjoy and what comes easily, and see which of ten aptitudes are strongest for you — and the activities that suit them.</p>
      <div class="aptitude-grid">${tiles}</div>
      <div class="stack">
        ${p
          ? `<button class="primary large" data-act="resume">Resume Survey (${answered} of ${p.order.length} answered)</button>
             <button data-act="start">Start Over</button>`
          : `<button class="primary large" data-act="start">Start Survey</button>`}
        ${state.history.length ? `<div>
          <button class="link" data-act="results">See My Latest Results</button>
          ${state.history.length > 1 ? `<button class="link" data-act="history">Past Results (${state.history.length})</button>` : ""}
        </div>` : ""}
      </div>
      <p class="footnote">About 10–15 minutes. Your answers are saved as you go and never leave this browser.</p>
    </section>`;
}

function renderSurvey() {
  const p = state.progress, q = currentQuestion();
  const answered = Object.keys(p.answers).length;
  const selected = p.answers[q.id];
  const last = p.currentIndex === p.order.length - 1;
  const complete = isComplete(p);

  const answers = q.kind === "choice"
    ? `<div class="choices" role="radiogroup" aria-label="${esc(q.instruction)}">${q.options.map((o, i) => `
        <button class="answer" role="radio" aria-checked="${selected === i}" data-answer="${i}">
          <span class="num">${i + 1}</span><span class="label">${esc(o.text)}</span>${selected === i ? '<span class="check" aria-hidden="true">✓</span>' : ""}
        </button>`).join("")}</div>`
    : `<div class="scale" role="radiogroup" aria-label="${esc(q.instruction)}">${q.scaleLabels.map((label, i) => `
        <button class="answer" role="radio" aria-checked="${selected === i + 1}" data-answer="${i + 1}">
          <span class="num">${i + 1}</span><span class="label">${esc(label)}</span>
        </button>`).join("")}</div>`;

  const center = complete
    ? `<button class="primary large center" data-act="finish">📊 See My Results</button>`
    : last ? `<button class="center" data-act="first-unanswered">Go to First Unanswered</button>` : `<span class="center"></span>`;

  app.innerHTML = `
    <section class="survey">
      <div>
        <div class="progress-head"><span>Question ${p.currentIndex + 1} of ${p.order.length}</span><span>${answered} answered</span></div>
        <div class="progress" role="progressbar" aria-label="Survey progress" aria-valuemin="0" aria-valuemax="${p.order.length}" aria-valuenow="${answered}">
          <div style="width:${(answered / p.order.length) * 100}%"></div>
        </div>
      </div>
      <div class="question" aria-live="polite">
        <p class="instruction">${esc(q.instruction)}</p>
        <p class="prompt">${esc(q.prompt)}</p>
        ${answers}
        <p class="tip">Tip: press ${q.kind === "choice" ? "1–4" : "1–5"} to answer, ← → to move.</p>
      </div>
      <div class="survey-footer">
        <button data-act="back" ${p.currentIndex === 0 ? "disabled" : ""}>‹ Back</button>
        ${center}
        <button data-act="next" ${last ? "disabled" : ""}>Next ›</button>
      </div>
    </section>`;
}

function ring(fit, color) {
  const r = 24, c = 2 * Math.PI * r;
  return `<div class="ring" aria-hidden="true">
    <svg viewBox="0 0 56 56" width="56" height="56">
      <circle cx="28" cy="28" r="${r}" fill="none" stroke="${color}" stroke-opacity="0.25" stroke-width="5"/>
      <circle cx="28" cy="28" r="${r}" fill="none" stroke="${color}" stroke-width="5" stroke-linecap="round"
        stroke-dasharray="${(fit / 100) * c} ${c}"/>
    </svg><span>${Math.round(fit)}%</span></div>`;
}

function renderResults() {
  const r = shownResult();
  const date = formatDate(r.completedAt);
  const change = isViewingLatest() ? latestChange(state.history, state.survey.aptitudes.map((a) => a.id)) : null;
  const delta = (id) => {
    const d = whole(change?.[id] ?? 0);
    return d ? `<span class="delta ${d > 0 ? "up" : "down"}" title="Change since your previous result">${d > 0 ? "▲" : "▼"}${Math.abs(d)}</span>` : "";
  };

  const bars = r.scores.map((s) => {
    const a = aptitude(s.aptitude);
    return `<div class="bar-row" style="--c:${LOOK[s.aptitude].color}">
      <span>${esc(a.name)}</span>
      <div class="bar-track"><div class="bar" style="width:calc(${s.score}% - 32px)"></div><span class="bar-value">${Math.round(s.score)}</span>${delta(s.aptitude)}</div>
    </div>`;
  }).join("");

  const strengths = r.scores.slice(0, 3).map((s, i) => {
    const a = aptitude(s.aptitude);
    return `<article class="strength" style="--c:${LOOK[s.aptitude].color}">
      <div class="emoji" aria-hidden="true">${LOOK[s.aptitude].emoji}</div>
      <div>
        <h3>${i + 1}. ${esc(a.name)} — ${Math.round(s.score)}</h3>
        <p>${esc(a.summary)}</p>
        ${s.evidence.length ? `<ul>${s.evidence.map((e) => `<li>${esc(e)}</li>`).join("")}</ul>` : ""}
      </div>
    </article>`;
  }).join("");

  const filtered = r.matches.filter((m) => state.category === "All" || m.category === state.category).slice(0, state.settings.topCount);
  const activities = filtered.map((m) => `
    <div class="activity">
      <div class="activity-info">
        <div class="activity-name">${esc(m.activity)}</div>
        <div class="chips"><span class="category">${esc(m.category)}</span>
          ${m.reasons.map((d) => `<span class="chip" style="--c:${LOOK[d].color}">${LOOK[d].emoji} ${esc(aptitude(d).name)}</span>`).join("")}
        </div>
      </div>
      ${ring(m.fit, LOOK[m.reasons[0]]?.color ?? "var(--accent)")}
      <span class="visually-hidden">${Math.round(m.fit)}% fit</span>
    </div>`).join("");

  const options = ["All", ...state.survey.categories]
    .map((c) => `<option ${c === state.category ? "selected" : ""}>${esc(c)}</option>`).join("");

  app.innerHTML = `
    <section class="results">
      <p class="print-only print-brand">✦ TalentFinder results</p>
      ${isViewingLatest() ? "" : `<div class="banner" role="status">
        <span>🕘 You're looking at a past result from ${esc(date)}.</span>
        <button data-act="history">Back to Past Results</button>
        <button data-act="results">See Latest</button>
      </div>`}
      <div class="results-head">
        <div><h1>Your natural aptitudes</h1><p>Based on ${r.answeredCount} answers · ${esc(date)}</p></div>
        <div class="head-buttons">
          ${state.history.length > 1 ? `<button data-act="history">Past Results</button>` : ""}
          <details class="menu">
            <summary>Export</summary>
            <div class="menu-items">
              <button data-act="export-pdf">Save as PDF…</button>
              <button data-act="export-md">Download Markdown</button>
            </div>
          </details>
          <button data-act="start">Retake Survey</button>
        </div>
      </div>
      <div>
        <div class="chart" role="img" aria-label="Aptitude scores from 0 to 100: ${r.scores.map((s) => `${aptitude(s.aptitude).name} ${Math.round(s.score)}`).join(", ")}">${bars}</div>
        ${change ? `<p class="footnote" style="margin-top:12px">▲▼ show the change since your previous result on ${esc(formatDate(state.history[state.history.length - 2].completedAt, { dateStyle: "medium" }))}.</p>` : ""}
      </div>
      <section><h2>Your top strengths</h2>${strengths}</section>
      <section>
        <div class="activities-head">
          <h2>Activities that suit you</h2>
          <label class="visually-hidden" for="category">Category</label>
          <select id="category">${options}</select>
        </div>
        ${activities || `<p class="footnote">No activities in this category.</p>`}
        <p class="footnote" style="margin-top:14px">Fit is a weighted average of the aptitudes each activity draws on. It's a pointer for what to try, not a verdict.</p>
        <p class="footnote print-only">Made with TalentFinder · ${esc(SITE_URL)}</p>
      </section>
    </section>`;
}

/** Line chart of the chosen aptitudes across results, evenly spaced by result number. */
function trendChart(shown) {
  const W = 640, H = 240, left = 8, right = 36, top = 10, bottom = 30;
  const n = state.history.length;
  const x = (i) => left + ((W - left - right) * (n === 1 ? 0.5 : i / (n - 1)));
  const y = (v) => top + (H - top - bottom) * (1 - v / 100);
  const grid = [0, 25, 50, 75, 100].map((v) =>
    `<line class="grid" x1="${left}" x2="${W - right}" y1="${y(v)}" y2="${y(v)}"/><text x="${W - right + 6}" y="${y(v) + 4}">${v}</text>`).join("");
  const labels = state.history.map((r, i) =>
    `<text x="${x(i)}" y="${H - 8}" text-anchor="${i === 0 ? "start" : i === n - 1 ? "end" : "middle"}">#${i + 1} · ${esc(formatDate(r.completedAt, { month: "short", day: "numeric" }))}</text>`).join("");
  const lines = state.survey.aptitudes.filter((a) => shown.has(a.id)).map((a) => {
    const pts = state.history.map((r, i) => [x(i), y(r.scores.find((s) => s.aptitude === a.id)?.score ?? 0)]);
    const c = LOOK[a.id].color;
    return `<polyline stroke="${c}" points="${pts.map((p) => p.join(",")).join(" ")}"/>` +
      pts.map(([px, py]) => `<circle cx="${px}" cy="${py}" r="4" fill="var(--bg)" stroke="${c}" stroke-width="2"/>`).join("");
  }).join("");
  const desc = state.survey.aptitudes.filter((a) => shown.has(a.id))
    .map((a) => `${a.name}: ${state.history.map((r) => Math.round(r.scores.find((s) => s.aptitude === a.id)?.score ?? 0)).join(" → ")}`).join("; ");
  return `<svg class="trend" viewBox="0 0 ${W} ${H}" role="img" aria-label="Scores over time. ${esc(desc)}">${grid}${labels}${lines}</svg>`;
}

function renderHistory() {
  const shown = new Set(state.trendAptitudes ?? latest().scores.slice(0, 3).map((s) => s.aptitude));
  const chips = state.survey.aptitudes.map((a) => `
    <button data-toggle="${a.id}" aria-pressed="${shown.has(a.id)}" style="--c:${LOOK[a.id].color}">${LOOK[a.id].emoji} ${esc(a.name)}</button>`).join("");
  const rows = [...state.history].reverse().map((r) => `
    <div class="history-row">
      <div class="activity-info">
        <div class="activity-name">${esc(formatDate(r.completedAt))}${r === latest() ? '<span class="badge">Latest</span>' : ""}</div>
        <div class="chips">${r.scores.slice(0, 3).map((s) =>
          `<span class="chip" style="--c:${LOOK[s.aptitude].color}">${LOOK[s.aptitude].emoji} ${esc(aptitude(s.aptitude).name)} ${Math.round(s.score)}</span>`).join("")}</div>
      </div>
      <div class="row-buttons">
        <button data-open="${esc(r.completedAt)}">Open</button>
        <button data-delete="${esc(r.completedAt)}" aria-label="Delete result from ${esc(formatDate(r.completedAt))}" title="Delete this result">🗑</button>
      </div>
    </div>`).join("");

  app.innerHTML = `
    <section class="results">
      <div class="results-head"><div><h1>Past Results</h1><p>${state.history.length === 1 ? "1 result" : `${state.history.length} results`}</p></div></div>
      ${state.history.length > 1 ? `<section>
        <h2>How your scores have changed</h2>
        ${trendChart(shown)}
        <p class="footnote" style="margin-top:10px">Choose which aptitudes to show:</p>
        <div class="toggle-chips">${chips}</div>
      </section>` : ""}
      <section><h2>All results</h2>${rows}</section>
    </section>`;
}

// ---------- Export ----------

/** Downloads the result on screen as Markdown, with the same text as the Mac app's export. */
function exportMarkdown() {
  const r = shownResult();
  const previous = previousTo(r, state.history);
  const text = markdown(r, state.survey, {
    date: formatDate(r.completedAt),
    previous,
    previousDate: previous ? formatDate(previous.completedAt) : null,
    activityCount: state.settings.topCount,
  });
  const url = URL.createObjectURL(new Blob([text], { type: "text/markdown;charset=utf-8" }));
  const a = Object.assign(document.createElement("a"), { href: url, download: `${fileName(r)}.md` });
  document.body.append(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

/** Opens the browser's print dialog; the print stylesheet turns the results page into a clean report. */
function exportPDF() {
  const before = document.title;
  document.title = fileName(shownResult()); // browsers use the title as the suggested PDF name
  window.addEventListener("afterprint", () => { document.title = before; }, { once: true });
  window.print();
}

// ---------- Events ----------

app.addEventListener("click", (e) => {
  const btn = e.target.closest("button");
  if (!btn) return;
  btn.closest("details.menu")?.removeAttribute("open");
  if (btn.dataset.answer !== undefined) return answer(Number(btn.dataset.answer));
  if (btn.dataset.open) return openResult(btn.dataset.open);
  if (btn.dataset.delete) return deleteResult(btn.dataset.delete);
  if (btn.dataset.toggle) {
    const shown = new Set(state.trendAptitudes ?? latest().scores.slice(0, 3).map((s) => s.aptitude));
    shown.has(btn.dataset.toggle) ? shown.delete(btn.dataset.toggle) : shown.add(btn.dataset.toggle);
    state.trendAptitudes = [...shown];
    return renderHistory();
  }
  ({
    start: startNew,
    resume: () => show("survey"),
    results: showLatest,
    history: () => show("history"),
    "export-md": exportMarkdown,
    "export-pdf": exportPDF,
    back: () => move(-1),
    next: () => move(1),
    finish,
    "first-unanswered": goToFirstUnanswered,
  })[btn.dataset.act]?.();
});

app.addEventListener("change", (e) => {
  if (e.target.id === "category") { state.category = e.target.value; renderResults(); }
});

document.getElementById("home-button").addEventListener("click", () => show("welcome"));
document.getElementById("history-button").addEventListener("click", () => show("history"));

document.addEventListener("keydown", (e) => {
  if ((e.metaKey || e.ctrlKey) && e.key === ",") { e.preventDefault(); openSettings(); return; }
  if (document.querySelector("dialog[open]") || e.metaKey || e.ctrlKey || e.altKey) return;
  if (state.screen !== "survey" || !state.progress) return;
  if (/^[1-5]$/.test(e.key)) {
    const q = currentQuestion();
    answer(q.kind === "choice" ? Number(e.key) - 1 : Number(e.key));
  } else if (e.key === "ArrowLeft") move(-1);
  else if (e.key === "ArrowRight") move(1);
  else if (e.key === "Enter" && isComplete(state.progress) && !(e.target instanceof HTMLButtonElement)) finish();
});

// ---------- Settings ----------

const settingsDialog = document.getElementById("settings-dialog");
const prefShuffle = document.getElementById("pref-shuffle");
const prefAuto = document.getElementById("pref-autoadvance");
const prefTop = document.getElementById("pref-topcount");

function openSettings() {
  prefShuffle.checked = state.settings.shuffle;
  prefAuto.checked = state.settings.autoAdvance;
  prefTop.value = String(state.settings.topCount);
  if (!settingsDialog.open) settingsDialog.showModal();
}

function saveSettings() {
  state.settings = { shuffle: prefShuffle.checked, autoAdvance: prefAuto.checked, topCount: Number(prefTop.value) };
  save(KEYS.settings, state.settings);
  if (state.screen === "results") renderResults();
}

document.getElementById("settings-button").addEventListener("click", openSettings);
[prefShuffle, prefAuto, prefTop].forEach((el) => el.addEventListener("change", saveSettings));

const confirmDialog = document.getElementById("confirm-dialog");
let onConfirm = null;

/** Asks before something that can't be undone; runs `action` only if the person clicks Delete. */
function confirmThen(title, message, action) {
  document.getElementById("confirm-title").textContent = title;
  document.getElementById("confirm-message").textContent = message;
  onConfirm = action;
  confirmDialog.showModal();
}

document.getElementById("reset-button").addEventListener("click", () =>
  confirmThen("Delete your saved answers and all past results?", "This can't be undone. Your settings are kept.", () => {
    settingsDialog.close();
    resetAll();
  }));
document.getElementById("confirm-delete").addEventListener("click", () => {
  confirmDialog.close();
  const action = onConfirm;
  onConfirm = null;
  action?.();
});

// ---------- Feedback ----------

const feedbackDialog = document.getElementById("feedback-dialog");
const feedbackMessage = document.getElementById("feedback-message");
const feedbackSend = document.getElementById("feedback-send");

function openFeedback() {
  if (settingsDialog.open) settingsDialog.close();
  feedbackDialog.showModal();
  feedbackMessage.focus();
}

/** Builds a pre-filled "new issue" link. The visitor reviews and submits it on GitHub. */
export function feedbackURL(kind, message) {
  const firstLine = message.split("\n")[0].slice(0, 60);
  const params = new URLSearchParams({
    title: `[${kind}] ${firstLine}`,
    body: `${message}\n\n---\nSent from the TalentFinder website (${kind}).`,
  });
  return `${REPO_ISSUES}?${params}`;
}

document.getElementById("feedback-button").addEventListener("click", openFeedback);
document.getElementById("settings-feedback-button").addEventListener("click", openFeedback);
feedbackMessage.addEventListener("input", () => { feedbackSend.disabled = !feedbackMessage.value.trim(); });
feedbackSend.addEventListener("click", () => {
  const kind = new FormData(document.getElementById("feedback-form")).get("kind");
  window.open(feedbackURL(kind, feedbackMessage.value.trim()), "_blank", "noopener");
  feedbackMessage.value = "";
  feedbackSend.disabled = true;
  feedbackDialog.close();
});

// ---------- Start ----------

async function init() {
  try {
    const res = await fetch("data/survey.json");
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    state.survey = await res.json();
    state.byId = Object.fromEntries(state.survey.questions.map((q) => [q.id, q]));
    // Finish moving a result saved by an earlier version into the history.
    if (load(KEYS.history) === null && state.history.length) {
      save(KEYS.history, state.history);
      save(KEYS.result, null);
    }
    // Drop saved progress that no longer fits the question set.
    if (state.progress && !state.progress.order?.every((id) => state.byId[id])) {
      state.progress = null;
      save(KEYS.progress, null);
    }
    render();
  } catch (err) {
    app.innerHTML = `<p class="error">Couldn't load the survey (${esc(err.message)}). Please reload the page.</p>`;
  }
}

init();
