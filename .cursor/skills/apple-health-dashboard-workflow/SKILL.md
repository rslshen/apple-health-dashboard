---
name: apple-health-dashboard-workflow
description: Builds and refines Apple Health quantified-self dashboards from local exports. Use when parsing Apple Health data, creating reusable R/flexdashboard templates, writing chart analysis, checking privacy, or reviewing dashboard screenshots.
disable-model-invocation: true
---

# Apple Health Dashboard Workflow

## Purpose

Help turn Apple Health exports into privacy-conscious, interactive dashboards about activity, sleep, workouts, and recovery.

## Privacy Rules

Always protect health data before editing, committing, or publishing:

- Never commit `data/raw/export.xml`.
- Never commit `data/tmp/`.
- Never commit `data/processed/*.csv` unless the user explicitly confirms it is fake/sample data.
- Never commit generated Plotly HTML from real data.
- Mention limitations from missing watch wear time, travel/jet lag, caffeine, stress, and illness.

## Standard Data Flow

```text
data/raw/export.xml
  -> scripts/parse_apple_health.R
  -> data/processed/daily_summary.csv
  -> data/processed/sleep_sessions.csv
  -> data/processed/workouts.csv
  -> flexdashboard Rmd
```

## Dashboard Structure

Use this page structure by default:

1. Overview: data source, methods, key metrics, questions
2. Activity: daily steps/energy, monthly averages, stand vs steps
3. Sleep: weekday sleep distribution, sleep vs daily steps
4. Workouts: workout types, monthly frequency, workout vs rest sleep
5. Recovery: HRV vs steps, rolling activity/sleep/energy
6. Insights: heatmap plus final summary

## Analysis Writing Rules

For each chart:

```markdown
**How to read:** Explain axes, colors, trend lines, rolling averages, scales, and transformations.

**Answer (Q# - topic):** State the chart-supported finding with numbers. Keep wording plain.
```

Use bullet points when a chart has several separate findings. Use a paragraph when the finding is simple.

Avoid unsupported claims. If a point needs context, mark it clearly as a possible explanation, not proof.

## Screenshot Review Loop

When the user shares dashboard screenshots:

1. Check whether labels, legends, and axes overlap.
2. Check whether analysis text only claims what the chart or data supports.
3. Rewrite text in plain language.
4. Add background context only when the user confirms it.
5. Re-render the dashboard after edits.

## Reusable Template Guidance

For templates intended for other users:

- Remove client-specific and personal references.
- Keep paths configurable or documented.
- Assume users provide their own processed CSVs.
- Include a clear privacy warning.
- Do not include personal screenshots, raw data, or generated HTML from real data.
