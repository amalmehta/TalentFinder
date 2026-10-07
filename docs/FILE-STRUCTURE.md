# File Structure

```
TalentFinder/
├── README.md                    At-a-glance overview with screenshots and links
├── TalentFinder.md              Project brief, decisions and changelog
├── Package.swift                Swift package for the core logic and its tests
├── project.yml                  XcodeGen spec for the Mac app
├── TalentFinder.xcodeproj/      Generated Xcode project (from project.yml)
├── Sources/TalentFinderCore/    Survey logic, with no UI code
│   ├── Aptitude.swift           The 10 aptitudes: names, icons, descriptions
│   ├── Question.swift           Question model (agree / ability / choice)
│   ├── QuestionBank.swift       All 60 survey questions and their weights
│   ├── Activity.swift           Activity model and the catalog of 47 activities
│   ├── Scoring.swift            Turns answers into scores, evidence and matches
│   └── Store.swift              Survey progress, feedback and JSON saving
├── Tests/TalentFinderCoreTests/ Unit tests for the question bank, scoring and saving
├── App/                         The SwiftUI Mac app
│   ├── TalentFinderApp.swift    App entry point, window, menus, Settings scene
│   ├── AppModel.swift           App state: current screen, survey, result
│   ├── ContentView.swift        Switches screens; toolbar; Feedback tab
│   ├── WelcomeView.swift        Start / resume screen; aptitude colours
│   ├── SurveyView.swift         One question at a time, with keyboard answers
│   ├── ResultsView.swift        Chart, top strengths, activity matches
│   ├── SettingsView.swift       Settings window (⌘,)
│   └── FeedbackView.swift       Feedback sheet
└── docs/
    ├── INSTRUCTIONS.md          Setup, running and using the app
    ├── SYSTEM-DESIGN.md         Architecture, flows, decisions, limits
    ├── FILE-STRUCTURE.md        This file
    └── screenshots/             Images used in the README
```

Ignored by git: `build/` (Xcode output), `.build/` (SwiftPM output), `.claude/`.
