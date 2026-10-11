// TalentFinder for the web: the same survey, scoring and screens as the Mac app.
// State lives in localStorage; nothing is sent anywhere.
import { score, accepts, newProgress, isComplete } from "./scoring.js";

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

const KEYS = { progress: "talentfinder.progress", result: "talentfinder.result", settings: "talentfinder.settings" };
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
  result: load(KEYS.result),
  settings: { ...DEFAULT_SETTINGS, ...(load(KEYS.settings) ?? {}) },
  category: "All",
};

const app = document.getElementById("app");
const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
const aptitude = (id) => state.survey.aptitudes.find((a) => a.id === id);

function show(screen) {
  state.screen = screen;
  render();
  window.scrollTo(0, 0);
  app.focus({ preventScroll: true });
}

function render() {
  if (state.screen === "survey" && !state.progress) state.screen = "welcome";
  if (state.screen === "results" && !state.result) state.screen = "welcome";
  document.title = { welcome: "TalentFinder", survey: "Survey · TalentFinder", results: "Your Results · TalentFinder" }[state.screen];
  ({ welcome: renderWelcome, survey: renderSurvey, results: renderResults })[state.screen]();
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
  state.result = { completedAt: new Date().toISOString(), ...score(state.progress.answers, state.survey) };
  state.progress = null;
  save(KEYS.result, state.result);
  save(KEYS.progress, null);
  show("results");
}

function resetAll() {
  state.progress = null;
  state.result = null;
  save(KEYS.progress, null);
  save(KEYS.result, null);
  show("welcome");
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
        ${state.result ? `<button class="link" data-act="results">See My Latest Results</button>` : ""}
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
  const r = state.result;
  const date = new Date(r.completedAt).toLocaleString(undefined, { dateStyle: "long", timeStyle: "short" });

  const bars = r.scores.map((s) => {
    const a = aptitude(s.aptitude);
    return `<div class="bar-row" style="--c:${LOOK[s.aptitude].color}">
      <span>${esc(a.name)}</span>
      <div class="bar-track"><div class="bar" style="width:calc(${s.score}% - 32px)"></div><span class="bar-value">${Math.round(s.score)}</span></div>
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
      <div class="results-head">
        <div><h1>Your natural aptitudes</h1><p>Based on ${r.answeredCount} answers · ${esc(date)}</p></div>
        <button data-act="start">Retake Survey</button>
      </div>
      <div class="chart" role="img" aria-label="Aptitude scores from 0 to 100: ${r.scores.map((s) => `${aptitude(s.aptitude).name} ${Math.round(s.score)}`).join(", ")}">${bars}</div>
      <section><h2>Your top strengths</h2>${strengths}</section>
      <section>
        <div class="activities-head">
          <h2>Activities that suit you</h2>
          <label class="visually-hidden" for="category">Category</label>
          <select id="category">${options}</select>
        </div>
        ${activities || `<p class="footnote">No activities in this category.</p>`}
        <p class="footnote" style="margin-top:14px">Fit is a weighted average of the aptitudes each activity draws on. It's a pointer for what to try, not a verdict.</p>
      </section>
    </section>`;
}

// ---------- Events ----------

app.addEventListener("click", (e) => {
  const btn = e.target.closest("button");
  if (!btn) return;
  if (btn.dataset.answer !== undefined) return answer(Number(btn.dataset.answer));
  ({
    start: startNew,
    resume: () => show("survey"),
    results: () => show("results"),
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
document.getElementById("reset-button").addEventListener("click", () => confirmDialog.showModal());
document.getElementById("confirm-delete").addEventListener("click", () => {
  confirmDialog.close();
  settingsDialog.close();
  resetAll();
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
