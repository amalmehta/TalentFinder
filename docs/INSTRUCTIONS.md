# Instructions

TalentFinder comes as a Mac app and as a website. Both have the same survey and scoring. Skip to [The website](#the-website) if that's all you need.

## What you need

- macOS 14 (Sonoma) or later
- Xcode 16 or later (built and tested with Xcode 26.5)
- Optional: [XcodeGen](https://github.com/yonaskolb/XcodeGen), only if you change `project.yml`

## Build and run

Open `TalentFinder.xcodeproj` in Xcode and press ⌘R. Or build from the terminal:

```bash
xcodebuild -project TalentFinder.xcodeproj -scheme TalentFinder -configuration Release -derivedDataPath build build
```

```bash
open build/Build/Products/Release/TalentFinder.app
```

If you edit `project.yml`, regenerate the Xcode project first:

```bash
xcodegen generate
```

## Run the tests

The survey, scoring and saving logic is tested as a Swift package:

```bash
swift test
```

The website's scorer is checked against the Swift one (needs Node 18 or later):

```bash
node --test web/tests/scoring.test.mjs web/tests/history.test.mjs
```

## Use it

1. **Start Survey** on the welcome screen. There are 60 questions and they take about 10–15 minutes.
2. Answer each question by clicking or by pressing **1–5** (or **1–4** for "which would you pick" questions). Use **←** and **→** to move between questions. With the default settings, the app moves on after each answer.
3. Your answers save as you go. Quit whenever you like and choose **Resume Survey** later.
4. When all 60 are answered, click **See My Results** (or press Return). You'll see:
   - a chart of your ten aptitude scores (0–100)
   - your top three strengths, each with the answers that pointed to it
   - the activities that suit you best, which you can filter by category
5. **Retake Survey** or **File ▸ New Survey** (⌘N) starts again. Every result you finish is kept.
6. After a retake, small ▲▼ numbers next to each score show how much it moved since your previous result.

## Past results

Open **Past Results** from the clock button in the toolbar, from the results screen, or from the welcome screen.

- **How your scores have changed:** a line chart with one point per result (#1, #2, …). Click the aptitude chips underneath to choose which lines to show. It starts with your latest top three.
- **All results:** newest first, each with its date and top three strengths. **Open** shows that result in full, with a banner reminding you it's a past one. The trash button deletes a result after you confirm.

## Settings (⌘,)

Open with **TalentFinder ▸ Settings…** (⌘,) or the gear button in the toolbar.

| Setting | Default | What it does |
|---|---|---|
| Shuffle question order | On | Mixes up the question order for each new survey |
| Move to the next question after answering | On | Moves on automatically after each answer |
| Activities to show | 10 | How many activity matches appear in your results |
| Show in Finder | — | Opens the folder where your data is saved |
| Reset… | — | Deletes your saved answers and all past results (feedback is kept) |

## Feedback

Click the small **Feedback** tab in the bottom-right corner, or use **Help ▸ Send Feedback…**. Feedback is saved to `Feedback.json` in the data folder. Nothing is sent anywhere.

## Where your data lives

`~/Library/Application Support/TalentFinder/`

- `Survey In Progress.json`: an unfinished survey
- `Result History.json`: every result you've finished, oldest first. If you used a version from before history existed, its `Latest Result.json` is moved in here automatically.
- `Feedback.json`: the feedback you've written

## The website

**Use it:** <https://amalmehta.github.io/TalentFinder/>. It works the same way as the Mac app: keys 1–5 to answer, ← → to move, Return to see your results. Answers and settings are saved in your browser's local storage, and nothing is sent anywhere.

- **Settings:** the gear button in the top right. ⌘, (Ctrl+, on Windows and Linux) also works, unless your browser keeps that shortcut for its own settings.
- **Feedback:** the small **Feedback** tab in the bottom-right corner opens a pre-filled GitHub issue for you to review and submit.
- **Past results:** the clock button in the top bar. It works the same as in the Mac app: a trend chart with aptitude chips, and a list of results to open or delete.
- **Reset:** Settings ▸ Reset… deletes the answers and all past results saved in this browser.

### Run it locally

The site is plain HTML, CSS and JavaScript, with no build step. It has to be served over HTTP, because opening `index.html` from disk can't load the survey data.

```bash
python3 -m http.server 8742 -d web
```

Then open <http://localhost:8742>.

### Change the questions or activities

Swift is the single source of truth. Edit `Sources/TalentFinderCore/QuestionBank.swift` or `Activity.swift`, then regenerate the website's data and test cases:

```bash
swift run ExportWebData
```

`swift test` fails if you forget to do this.

### Deploy

Pushing changes under `web/` to `main` runs the **Website** GitHub Actions workflow. It runs the parity tests first, then publishes `web/` to GitHub Pages. You can also run it by hand from the repo's Actions tab.
