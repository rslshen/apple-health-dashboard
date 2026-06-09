# Apple Health Dashboard

Interactive R/flexdashboard workflow for turning an Apple Health export into a quantified-self dashboard about activity, sleep, workouts, and recovery.

## What Is Included

- `Course_Project_Dashboard.Rmd` - the finished dashboard source used for this project.
- `scripts/parse_apple_health.R` - parser that converts Apple Health `export.xml` into processed CSV files.
- `template/Apple_Health_Dashboard_Template.Rmd` - reusable dashboard template for other Apple Health exports.
- `docs/WORKFLOW.md` - generic AI-assisted workflow for building and refining this type of dashboard.
- `.cursor/skills/apple-health-dashboard-workflow/SKILL.md` - project-local Cursor skill for repeating the workflow.

## Privacy Notice

Apple Health data is sensitive. It can reveal sleep patterns, workout habits, biometrics, recovery signals, and location-adjacent routines.

This repository intentionally excludes:

- `data/raw/export.xml`
- `data/tmp/`
- `data/processed/*.csv`
- `*.html`
- local PDFs and R session files

Generated HTML dashboards are also excluded because interactive Plotly HTML can embed underlying data.

## Expected Local Data Layout

Keep private data local in this structure:

```text
data/
  raw/
    export.xml
  processed/
    daily_summary.csv
    sleep_sessions.csv
    workouts.csv
```

The tracked repository keeps only folder placeholders, not personal data.

## Recreate The Dashboard Locally

1. Export Apple Health data from iPhone Health app.
2. Put `export.xml` at `data/raw/export.xml`.
3. Parse the export:

```bash
Rscript scripts/parse_apple_health.R
```

4. Render the finished dashboard:

```bash
RSTUDIO_PANDOC="/Applications/quarto/bin/tools/aarch64" Rscript -e 'rmarkdown::render("Course_Project_Dashboard.Rmd")'
```

5. Or render the reusable template:

```bash
RSTUDIO_PANDOC="/Applications/quarto/bin/tools/aarch64" Rscript -e 'rmarkdown::render("template/Apple_Health_Dashboard_Template.Rmd")'
```

## Reusable Template

The template expects the three processed CSV files produced by `scripts/parse_apple_health.R`:

- `daily_summary.csv`
- `sleep_sessions.csv`
- `workouts.csv`

Users can replace the local data files with their own processed Apple Health data and render the template to get a similar dashboard.

## Data Limitations To Mention

When interpreting results, note that:

- Missing watch wear time can create incomplete step, stand, workout, HRV, or sleep records.
- Travel, jet lag, caffeine, stress, and illness can affect sleep and recovery outside the activity measures.
- Correlations in this dashboard describe patterns; they do not prove causation.
