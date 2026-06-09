# AI-Assisted Apple Health Dashboard Workflow

This document describes a reusable workflow for building an Apple Health quantified-self dashboard with an AI coding assistant. It is written generically so it can be adapted for personal projects, client work, tutorials, or productized templates.

## Goal

Turn a personal Apple Health export into an interactive dashboard that answers clear questions about movement, sleep, workouts, and recovery.

## Inputs

- Apple Health `export.xml`
- R environment with `tidyverse`, `lubridate`, `flexdashboard`, `plotly`, `scales`, and `htmltools`
- Optional screenshots of each dashboard page for visual review

## Workflow

### 1. Protect Privacy First

Before analysis or publishing:

- Keep raw Apple Health exports local.
- Do not commit `export.xml`, processed CSVs, or generated Plotly HTML.
- Add `.gitignore` rules for raw data, processed data, temp files, and generated HTML.
- Mention limitations from missing watch wear time and external factors such as travel, jet lag, caffeine, stress, and illness.

### 2. Parse Apple Health Data

Use a parser to extract only the metrics needed for the dashboard:

- Daily steps
- Active energy
- Stand hours
- Sleep duration
- Workouts
- Resting heart rate
- HRV

Output three processed CSVs:

- `daily_summary.csv`
- `sleep_sessions.csv`
- `workouts.csv`

### 3. Define Questions Before Charts

Use 5-7 questions that require interpretation, not only counts. Example categories:

- Does activity relate to sleep?
- Do workouts affect same-night or next-night sleep?
- Which weekdays show different activity or sleep patterns?
- Do high-activity days relate to recovery signals?
- How do activity, energy, and sleep change over time?
- Which workout types dominate?

### 4. Build A Multi-Page Dashboard

Recommended page structure:

- Overview: data source, methods, key metrics, questions
- Activity: daily trend, monthly averages, stand vs steps
- Sleep: weekday sleep distribution, sleep vs daily steps
- Workouts: workout types, monthly frequency, workout vs rest sleep
- Recovery: HRV vs steps, 7-day rolling trends
- Insights: heatmap plus final summary

Use multiple chart types: line charts, bar charts, scatterplots, boxplots, heatmaps, and paired comparisons.

### 5. Write Plain Analysis Text

For each chart, use this structure:

```markdown
**How to read:** Explain axes, color, trend lines, scale, and any transformations.

**Answer (Q# - topic):** State the finding with numbers. Stay close to what the chart shows.
```

Use bullets when one chart has several distinct findings. Use a paragraph when the conclusion is simple.

### 6. Review With Screenshots

After rendering:

1. Review one page at a time.
2. Compare the chart and written conclusion.
3. Remove claims not visible from the chart unless supported by data.
4. Add background only when it explains a visible pattern.
5. Check layout, overlapping labels, legends, and right-column text length.

### 7. Separate Personal Dashboard From Reusable Template

Keep the finished personal dashboard for private use. Create a generic template that:

- Uses neutral titles and wording.
- Does not include personal explanations.
- Reads the same processed CSV schema.
- Includes data limitation language.
- Lets other users replace the data and render their own dashboard.

## Publishing Checklist

Before pushing to GitHub:

- [ ] `data/raw/` is ignored.
- [ ] `data/tmp/` is ignored.
- [ ] `data/processed/*.csv` is ignored.
- [ ] `*.html` is ignored unless generated from fake/sample data.
- [ ] README includes privacy warning.
- [ ] Template has no personal data or context-specific references.
- [ ] Skill/workflow docs do not include private data.
