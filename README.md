# TalentFinder

Find out what you're naturally good at. A 60-question survey scores ten aptitudes, then suggests the jobs, sports, hobbies and creative pursuits that suit them. It comes as a Mac app and as a website.

**[Try it in your browser →](https://amalmehta.github.io/TalentFinder/)**

![TalentFinder results: a bar chart of ten aptitude scores](docs/screenshots/Results.jpg)

| Survey | Strengths and activities | Settings (⌘,) |
|---|---|---|
| ![Survey question](docs/screenshots/Survey.jpg) | ![Top strengths and activity matches](docs/screenshots/Strengths%20and%20Activities.jpg) | ![Settings window](docs/screenshots/Settings.jpg) |

| Website | On a phone |
|---|---|
| ![Website results in dark mode](docs/screenshots/Website%20Results.jpg) | ![Website survey on a phone](docs/screenshots/Website%20on%20a%20Phone.jpg) |

```mermaid
flowchart LR
    A[60 answers] --> B[Scorer] --> C[10 aptitude scores<br/>with evidence] --> D[Ranked activities]
```

## Links

- [Website](https://amalmehta.github.io/TalentFinder/)
- [Instructions](docs/INSTRUCTIONS.md): setup, running and using the Mac app and the website
- [System Design](docs/SYSTEM-DESIGN.md): how it works and why
- [File Structure](docs/FILE-STRUCTURE.md): what's where
