# TalentFinder

A Mac app that works out your natural aptitudes from a 60-question survey, then suggests the jobs, sports, hobbies and creative pursuits that suit them.

![TalentFinder results: a bar chart of ten aptitude scores](docs/screenshots/Results.jpg)

| Survey | Strengths and activities | Settings (⌘,) |
|---|---|---|
| ![Survey question](docs/screenshots/Survey.jpg) | ![Top strengths and activity matches](docs/screenshots/Strengths%20and%20Activities.jpg) | ![Settings window](docs/screenshots/Settings.jpg) |

```mermaid
flowchart LR
    A[60 answers] --> B[Scorer] --> C[10 aptitude scores<br/>with evidence] --> D[Ranked activities]
```

## Links

- [Instructions](docs/INSTRUCTIONS.md): setup, running and using the app
- [System Design](docs/SYSTEM-DESIGN.md): how it works and why
- [File Structure](docs/FILE-STRUCTURE.md): what's where
