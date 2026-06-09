# Apple Health Dashboard

Interactive R/flexdashboard workflow for turning an Apple Health export into a quantified-self dashboard about activity, sleep, workouts, and recovery.

## What Is Included

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

## How To Reuse This Repo

Share or clone the whole repository, not just individual files. The repo contains the parser, reusable dashboard template, privacy rules, and AI workflow notes together.

For someone using this with their own Apple Health data:

### 1. Clone the repo

```bash
git clone https://github.com/rslshen/apple-health-dashboard.git
cd apple-health-dashboard
```

### 2. Install the R packages

In R, install the packages used by the parser and dashboard:

```r
install.packages(c(
  "tidyverse",
  "lubridate",
  "flexdashboard",
  "plotly",
  "scales",
  "htmltools"
))
```

### 3. Export Apple Health data

On iPhone:

1. Open the Health app.
2. Tap your profile picture.
3. Select **Export All Health Data**.
4. Unzip the export.
5. Copy `apple_health_export/export.xml` into this repo at:

```text
data/raw/export.xml
```

The file should stay local. Do not commit it.

### 4. Parse the Apple Health export

Run:

```bash
Rscript scripts/parse_apple_health.R
```

This creates:

```text
data/processed/daily_summary.csv
data/processed/sleep_sessions.csv
data/processed/workouts.csv
```

These CSV files also stay local and are ignored by git.

### 5. Render the reusable dashboard template

Use the template for a generic dashboard:

```bash
RSTUDIO_PANDOC="/Applications/quarto/bin/tools/aarch64" Rscript -e 'rmarkdown::render("template/Apple_Health_Dashboard_Template.Rmd")'
```

If Pandoc is already available on your system, this shorter command may work:

```bash
Rscript -e 'rmarkdown::render("template/Apple_Health_Dashboard_Template.Rmd")'
```

The generated HTML is ignored by git because it may embed personal data.

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
