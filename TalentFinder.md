PROJECT NAME: TalentFinder

META-INSTRUCTIONS:

<Read it all before acting. Ask about anything unclear, contradictory or
 underspecified — before starting and mid-build. Ask in the question widget
 (AskUserQuestion): related questions batched, concrete options, your
 recommendation first. Plain text only if the widget isn't available.>

<Don't expand scope. Anything not listed here is a proposal, including changes
 to this file — propose it, don't do it.>

<Prefer doing over describing: run the code, write the files, test it.>

<Always in scope, no proposal needed: when it goes on GitHub, a README that is
 easy to read at a glance — a line on what it is, then clear visuals
 (screenshots, a diagram or a chart), then links. Everything else goes in
 linked files: docs/INSTRUCTIONS.md (setup, run, use),
 docs/SYSTEM-DESIGN.md (see below) and docs/FILE-STRUCTURE.md (what's where). If what you're
 building is an application rather than a script, also a small unobtrusive feedback tab, and a settings
 button or tab (⌘, on the Mac) that gathers its preferences in one place.>

<If what you're building is an application, build it as a Mac app first; the
 website comes after, as its own step.>

<Name things the way a person would say them — "Goal Tracker", not
 goal_tracker — for the app, its windows, titles, files people open, repo
 descriptions and README headings. When you create the GitHub repo, name it
 with no "_" or "-": one word or joined words, e.g. GoalTracker.>

<Always in scope: a system design doc in the codebase, docs/SYSTEM-DESIGN.md,
 kept current as the build changes. Cover the architecture (with a Mermaid
 diagram), each component's job, the main flows, where data lives, the key
 design decisions and their trade-offs, how it's tested, and known limits.>

<Finish by listing every deliverable: path, what it is, how to check it works.>

<Git rules (no Claude attribution, never commit .claude/) are in
 ~/.claude/CLAUDE.md and apply on their own — nothing to repeat here.>

<Keep the changelog at the bottom current.>

CONTEXT:

figure out your natural aptitude for certain activities based on a detailed survey

DELIVERABLES:

<What you want at the end: the app, files, links. One per line.>

OPEN QUESTIONS / ASSUMPTIONS:

Asked and answered (2026-10-06):
- Activities covered: a broad mix (work, creative, sport, hobbies) across ten aptitudes.
- Scoring: local and rule-based, with no AI and no network.
- Survey length: 60 questions, about 10–15 minutes, with save and resume.
- Scope this session: the native Mac app plus local git. The GitHub push and the website are proposals for later.
- 2026-10-07: asked to push to GitHub. Pushed to amalmehta/TalentFinder (private at first, made public 2026-10-11).

Decided without asking:
- SwiftUI, macOS 14+, with the core logic in a separate Swift package (TalentFinderCore) so it can be tested with `swift test`.
- The ten aptitudes and all question and activity weights are original. They are loosely inspired by multiple intelligences and RIASEC, and are not psychometrically validated.
- Only the latest result is kept, with no history. (Superseded 2026-10-11: history added.)
- The feedback tab saves to Feedback.json on the Mac. Nothing is sent, because the brief names no destination.
- Settings: shuffle questions, auto-advance, number of activities shown, show the data folder, and reset data.
- Data is saved as JSON in ~/Library/Application Support/TalentFinder.

Website (asked and answered 2026-10-11):
- Plain static site (HTML, CSS, JS) in `web/`, with no build step and no dependencies.
- Swift stays the single source of truth. `swift run ExportWebData` writes the survey JSON and the parity fixtures, and the JS scorer must match Swift exactly.
- Hosted on GitHub Pages from this repo, deployed by a GitHub Actions workflow.
- Website feedback opens a pre-filled GitHub issue.

Website decisions made without asking:
- Made the Swift scorer's iteration order and tie-breaks deterministic, which was needed for exact parity. Mac app results are unchanged.
- Aptitude icons on the web are emoji, because SF Symbols don't exist there; colours match the Mac app.
- Website settings are the same as the Mac app's minus "Show in Finder", with a gear button plus ⌘/Ctrl+,.

Result history (asked and answered 2026-10-11):
- In both the Mac app and the website, each with its own history; they still don't sync.
- A list of past results to open, a trend chart to compare across retakes, and deleting single entries.
- Every result is kept until deleted or reset.

Result history decisions made without asking:
- Results are identified by their completion time, so the saved format didn't change; the old single result moves into the history automatically.
- The latest result also shows ▲▼ change since the previous one.
- The trend chart spaces results evenly (#1, #2, …) instead of by calendar time, and starts with the latest top three aptitudes.

Proposals (not done):
- Exporting results to PDF or Markdown.
- An app icon, plus signing and notarisation for distribution.

CHANGELOG:

- 2026-10-06 — created
- 2026-09-15 — added meta-instruction: built-out applications include a small feedback tab
- 2026-09-15 — added meta-instruction: no "Claude" attribution in commits, PRs, or branches
- 2026-09-16 — added meta-instruction: always include a README when adding to GitHub
- 2026-09-16 — changed meta-instruction: ask clarifying questions in the question widget
- 2026-09-17 — added meta-instructions: Claude never a contributor; never commit .claude/
- 2026-09-26 — compressed the meta-instructions and every field prompt; git rules moved to the global instruction file
- 2026-09-27 — added meta-instruction: applications are built as a Mac app first, then a website
- 2026-09-28 — folded inputs, instructions, constraints, deliverables and done criteria into one free-form CONTEXT
- 2026-09-28 — changed meta-instruction: a README on GitHub always includes a visual
- 2026-09-28 — added meta-instruction: name things like a person would, never snake_case
- 2026-09-28 — changed meta-instruction: README leads with visuals; instructions live in a linked guide
- 2026-09-28 — changed meta-instruction: README is visuals and links; details in docs/INSTRUCTIONS.md and docs/FILE-STRUCTURE.md
- 2026-09-29 — changed meta-instruction: GitHub repo names have no "_" or "-"
- 2026-10-02 — added a DELIVERABLES field after CONTEXT
- 2026-10-02 — added meta-instruction: every project has a system design doc at docs/SYSTEM-DESIGN.md
- 2026-10-05 — added meta-instruction: applications include a settings button or tab
- 2026-10-06 — built v1 of the Mac app (60-question survey, ten aptitudes, activity matches, Settings, feedback tab), with tests, docs and screenshots
- 2026-10-07 — pushed to GitHub as a private repo: https://github.com/amalmehta/TalentFinder
- 2026-10-11 — made the GitHub repo public
- 2026-10-11 — built the website version (web/), with JSON exported from Swift, exact JS↔Swift parity tests, and GitHub Pages deployment
- 2026-10-11 — added result history to the Mac app and website: past results list, trend chart, change since last time, delete; old saved results migrate automatically
