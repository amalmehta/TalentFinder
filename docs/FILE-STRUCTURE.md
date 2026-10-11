# File Structure

```
TalentFinder/
├── README.md                    At-a-glance overview with screenshots and links
├── TalentFinder.md              Project brief, decisions and changelog
├── Package.swift                Swift package for the core logic and its tests
├── project.yml                  XcodeGen spec for the Mac app
├── TalentFinder.xcodeproj/      Generated Xcode project (from project.yml)
├── .github/workflows/
│   └── website.yml              Runs the web tests, then publishes web/ to GitHub Pages
├── Sources/ExportWebData/       `swift run ExportWebData`: writes the website's JSON
├── Sources/TalentFinderCore/    Survey logic, with no UI code
│   ├── Aptitude.swift           The 10 aptitudes: names, icons, descriptions
│   ├── Question.swift           Question model (agree / ability / choice)
│   ├── QuestionBank.swift       All 60 survey questions and their weights
│   ├── Activity.swift           Activity model and the catalog of 47 activities
│   ├── Scoring.swift            Turns answers into scores, evidence and matches
│   ├── ResultHistory.swift      Past results: add, remove, trend series, latest change
│   ├── Store.swift              Progress, result history, feedback; JSON saving
│   └── WebExport.swift          Builds the website's survey data and parity test cases
├── Tests/TalentFinderCoreTests/ Unit tests: question bank, scoring, saving, history, web export
├── App/                         The SwiftUI Mac app
│   ├── TalentFinderApp.swift    App entry point, window, menus, Settings scene
│   ├── AppModel.swift           App state: screen, survey, result history
│   ├── ContentView.swift        Switches screens; toolbar; Feedback tab
│   ├── WelcomeView.swift        Start / resume / results screen; aptitude colours
│   ├── SurveyView.swift         One question at a time, with keyboard answers
│   ├── ResultsView.swift        Chart (with change since last time), strengths, activities
│   ├── HistoryView.swift        Past Results: trend chart, aptitude chips, list
│   ├── SettingsView.swift       Settings window (⌘,)
│   └── FeedbackView.swift       Feedback sheet
├── web/                         The website (static, no build step)
│   ├── index.html               Page shell; Settings, Feedback and confirm dialogs
│   ├── styles.css               Light and dark themes, phone layout
│   ├── favicon.svg              Tab icon
│   ├── js/app.js                Screens, keyboard, settings, feedback, browser storage
│   ├── js/scoring.js            Port of the Swift scorer
│   ├── js/history.js            Port of ResultHistory, plus migrating old saved results
│   ├── data/survey.json         Questions, activities and aptitudes (generated from Swift)
│   └── tests/                   Parity and history tests; fixtures generated from Swift
└── docs/
    ├── INSTRUCTIONS.md          Setup, running and using the Mac app and website
    ├── SYSTEM-DESIGN.md         Architecture, flows, decisions, testing, limits
    ├── FILE-STRUCTURE.md        This file
    └── screenshots/             Images used in the README
```

Ignored by git: `build/` (Xcode output), `.build/` (SwiftPM output), `.claude/`.

Generated, don't edit by hand: `web/data/survey.json` and `web/tests/fixtures.json`. Run `swift run ExportWebData` to regenerate them.
