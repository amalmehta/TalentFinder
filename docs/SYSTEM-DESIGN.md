# System Design

TalentFinder comes as a native macOS app (SwiftUI, macOS 14+) and as a static website. In both, the user answers a 60-question survey, and the app scores ten aptitudes and ranks 47 activities by how well they fit. Everything runs and stays on the user's device. There is no server, no account and no API key. The Swift package is the single source of truth: the website loads JSON exported from it, and its scorer is a port that is tested to give identical results.

## Architecture

```mermaid
flowchart TB
    subgraph App["TalentFinder.app (SwiftUI)"]
        TA[TalentFinderApp<br/>window, menus, Settings scene]
        AM[AppModel<br/>screen + survey + result state]
        V1[WelcomeView]
        V2[SurveyView]
        V3[ResultsView]
        V4[SettingsView]
        V5[FeedbackView + Feedback tab]
        UD[(UserDefaults<br/>preferences)]
    end
    subgraph Core["TalentFinderCore (Swift package, no UI)"]
        QB[QuestionBank<br/>60 questions]
        AC[ActivityCatalog<br/>47 activities]
        SC[Scorer]
        ST[Store]
    end
    FS[("~/Library/Application Support/TalentFinder<br/>Survey In Progress.json<br/>Latest Result.json<br/>Feedback.json")]

    TA --> AM
    AM --> V1 & V2 & V3
    TA --> V4
    AM --> V5
    V4 & V3 & AM --> UD
    AM --> QB
    AM --> SC
    SC --> QB & AC
    AM --> ST --> FS

    subgraph Web["Website (web/, static, GitHub Pages)"]
        JA[app.js<br/>screens, keys, settings, feedback]
        JS[scoring.js<br/>port of Scorer]
        SJ[(data/survey.json)]
        LS[(localStorage)]
    end
    EX[ExportWebData<br/>swift run] --> SJ
    EX --> FX[(tests/fixtures.json)]
    Core --> EX
    JA --> JS --> SJ
    JA --> LS
    JA -. feedback .-> GH[GitHub new-issue page]
    FX -. parity test .-> JS
```

## Components

| Component | Job |
|---|---|
| `Aptitude` | The ten aptitudes measured: name, SF Symbol and a plain-English description. |
| `Question` / `QuestionBank` | 60 questions in three kinds. **Agreement** items are rated from Strongly disagree to Strongly agree. **Ability** items are rated from Very hard to Very easy. **Choice** items ask "which would you pick?" with four options. Each scale item has weights per aptitude and may be reverse-keyed. Each choice option has its own weights. |
| `Activity` / `ActivityCatalog` | 47 activities in four categories (Work & Study, Creative, Sport & Movement, Hobbies), each with weights for the aptitudes it draws on. |
| `Scorer` | A pure function from answers to a `SurveyResult`. The result holds 0–100 scores per aptitude, up to three evidence lines each, and every activity ranked by fit with its top two reasons. |
| `Store` | Reads and writes the progress, result and feedback JSON files in one folder. Tests point it at a temporary folder. |
| `AppModel` | `@Observable` app state. It tracks the current screen, the survey in progress and the latest result. It starts, answers, moves, finishes and resets the survey, saves after every change and saves feedback. |
| Views | Welcome (start or resume), Survey (one question at a time, keys 1–5, arrow keys), Results (Swift Charts bar chart, strengths, filterable activity list), Settings (⌘,), and Feedback (a sheet opened from the corner tab, the Help menu or Settings). |
| `WebExport` / `ExportWebData` | Encodes the aptitudes, questions and activities as `web/data/survey.json`. Also scores 21 answer sets (one favouring each aptitude, neutral, partial, invalid, empty and six seeded random sets) with the Swift `Scorer` and writes them to `web/tests/fixtures.json`. |
| `web/js/scoring.js` | A line-for-line port of `Scorer`, with the same loop order, arithmetic and tie-breaks, so the floating-point results are bit-identical. It also creates new (optionally shuffled) survey progress. |
| `web/js/app.js` | The website: the same three screens as the Mac app, rendered from templates, plus keyboard handling, a Settings dialog (gear button or ⌘/Ctrl+,), the Feedback tab, and guarded `localStorage` persistence. |
| `.github/workflows/website.yml` | On pushes to `web/`, runs the parity tests, then publishes `web/` to GitHub Pages. |

## Main flows

**Taking the survey.** Start Survey creates a `SurveyProgress` with all 60 question ids, shuffled if the setting is on. Each answer updates `answers[id]`, auto-advances if that setting is on, and saves `Survey In Progress.json`. If the app quits, Resume picks up at the same question.

**Scoring.** Once every question is answered, See My Results runs `Scorer.score`:

- **Scale items.** An answer *v* (1–5) becomes a level of (*v*−1)/4, flipped to 1−level for reverse-keyed items. Each aptitude earns *weight × level* and could have earned *weight*.
- **Choice items.** The chosen option earns its weight for each aptitude it lists. The most an aptitude could have earned is the highest weight any option gives it.
- **Aptitude score** = earned ÷ possible × 100. An aptitude with nothing to score is 0.
- **Evidence.** The answers that contributed most (scale levels above neutral, or chosen options), turned into short sentences.
- **Activity fit.** The weighted average of the aptitude scores the activity draws on. The reasons are the two aptitudes contributing the most.

The result is saved as `Latest Result.json` and the progress file is deleted.

**Settings.** The values are `@AppStorage` in UserDefaults, read when they matter: shuffle when a survey starts, auto-advance on each answer, and the activity count when results are drawn. Reset deletes the progress and result files and keeps feedback.

**Feedback.** In the Mac app, the sheet appends `{date, kind, message}` to `Feedback.json`. Nothing is transmitted. On the website, the dialog opens `github.com/amalmehta/TalentFinder/issues/new`, with the title (`[Kind] first line`) and body filled in. The visitor reviews and submits it from their own GitHub account, so the site never sends anything itself.

**Website.** The page loads `data/survey.json`, then renders the welcome, survey or results screen. Progress, the latest result and settings live in `localStorage` under `talentfinder.*` keys. Every read and write is wrapped so the site still works, in memory only, when storage is blocked. Saved progress that refers to questions that no longer exist is dropped on load.

**Keeping the two in step.** When the questions or activities change, run `swift run ExportWebData` to regenerate both JSON files. `swift test` fails if the committed files differ from what the Swift code would produce. `node --test web/tests/scoring.test.mjs` fails if the JS scorer's output differs from the Swift fixtures at all; the comparison is exact, not within a tolerance.

## Where data lives

| Data | Location |
|---|---|
| Survey in progress | `~/Library/Application Support/TalentFinder/Survey In Progress.json` |
| Latest result | `~/Library/Application Support/TalentFinder/Latest Result.json` |
| Feedback | `~/Library/Application Support/TalentFinder/Feedback.json` |
| Preferences | UserDefaults domain `com.amalmehta.TalentFinder` |
| Questions and activities | Compiled into the app (`QuestionBank.swift`, `Activity.swift`), and exported to `web/data/survey.json` for the website |
| Website progress, result, settings | The visitor's browser `localStorage` (`talentfinder.progress`, `.result`, `.settings`) |
| Website feedback | GitHub Issues on amalmehta/TalentFinder, if the visitor submits it |

## Key decisions and trade-offs

- **Local, rule-based scoring instead of AI.** Results are transparent, reproducible, testable and private, and work offline. The trade-off is that the written feedback comes from fixed descriptions plus the user's own answers, not a tailored narrative.
- **An original framework.** The ten aptitudes are loosely inspired by multiple-intelligences and interest (RIASEC-style) models, but the questions and weights are written for this app and have not been psychometrically validated. Results are worded as pointers, not verdicts.
- **A mix of question kinds.** Agreement, ability and forced-choice items reduce the pull to rate everything highly. One reverse-keyed item per aptitude catches straight-lining.
- **The core lives in a package separate from the UI.** All logic sits in `TalentFinderCore` and is tested with `swift test`, without launching the app. The app target only depends on it.
- **JSON files instead of SwiftData or Core Data.** The data is tiny, the files are readable, and there is no migration work. Only the latest result is kept.
- **XcodeGen with the generated project committed.** `project.yml` is the source of truth, but the `.xcodeproj` is committed so XcodeGen isn't needed just to build.
- **A Window scene instead of WindowGroup.** The app has a single main window, so ⌘N means "New Survey" rather than "new window".
- **A plain static website instead of a framework or SwiftWasm.** There are no dependencies and no build step, the page loads fast, and it can be hosted anywhere. The cost is a second scorer to maintain, which the exported data and exact parity tests keep honest.
- **Exported JSON instead of copying the questions into JS.** Questions and activities are defined once, in Swift, and the website can't drift from the Mac app without a test failing.
- **Deterministic scoring order.** The Swift scorer walks aptitudes in a fixed order rather than dictionary order, and breaks ties by position. That makes results identical on every run and lets the JS port match them exactly.
- **GitHub issues for website feedback.** It needs no backend and puts no email address on the page, and nothing is sent without the visitor's say. The cost is that a visitor needs a GitHub account to send feedback.

## How it's tested

- **Unit tests** (`swift test`, 19 tests):
  - Question bank: 60 unique ids; five primary items and one reverse-keyed item per aptitude; every aptitude appears in at least three choice items; every aptitude has a matching activity.
  - Scorer: maxing out each aptitude ranks it first; reverse-keyed items work; all-neutral answers score 50; invalid answers are ignored; choices give full credit and evidence; matches follow strengths; quotes aren't doubled.
  - Store: progress and result round trips; reset keeps feedback; a shuffled order still covers every question.
  - Web export: the committed `survey.json` and `fixtures.json` are current; scoring is deterministic.
- **Website parity tests** (`node --test web/tests/scoring.test.mjs`, 24 tests): the JS scorer exactly matches all 21 Swift fixtures (scores, evidence, activity order, fits and reasons); it rejects invalid answers; a shuffled survey covers every question. These also run in CI before each deploy.
- **Manual end-to-end run** of the built app, driven in the background through accessibility automation:
  - starting a survey and answering by click and by keyboard, with auto-advance
  - resuming a saved survey and finishing it to see the results
  - Settings from the menu, and saving feedback (checked in `Feedback.json`)
- **Website end-to-end checks** in a browser, driving the real page's buttons and key handlers:
  - start, answer by click and by keyboard, go back, finish
  - results render, and the category filter works
  - settings save and apply; ⌘, opens Settings
  - the feedback link has the right title and body
  - resume works after a reload; reset clears progress and result but keeps settings
- **Visual checks** with headless Chrome, in light and dark mode at 1100 px and at phone width (390 px), with no horizontal overflow.

## Known limits

- The questions and weights are not psychometrically validated. Scores are relative indicators.
- Only the latest result is kept. There is no history or comparison over time.
- There is no export or sharing of results.
- English only. The text is hard-coded rather than localised.
- Feedback from the Mac app stays on the Mac; someone has to open `Feedback.json` to read it. Feedback from the website needs a GitHub account.
- The app is ad-hoc signed and not notarised, so other Macs will show a Gatekeeper warning.
- Results on the website live in one browser only and don't sync with the Mac app.
- In some browsers ⌘, opens the browser's own settings instead of TalentFinder's; the gear button always works.
- The website needs JavaScript and must be served over HTTP. Opening `index.html` from disk won't load the survey.
