#!/usr/bin/env Rscript
# Fast Apple Health parser: pre-filter XML with grep, then aggregate in R.

suppressPackageStartupMessages({
  library(tidyverse)
  library(lubridate)
})

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
project_root <- if (length(file_arg)) {
  normalizePath(file.path(dirname(sub("^--file=", "", file_arg)), ".."), mustWork = TRUE)
} else {
  getwd()
}

raw_path <- file.path(project_root, "data", "raw", "export.xml")
tmp_dir <- file.path(project_root, "data", "tmp")
out_dir <- file.path(project_root, "data", "processed")
dir.create(tmp_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(raw_path)) stop("Missing export.xml at ", raw_path)

record_pattern <- paste(
  c(
    "HKQuantityTypeIdentifierStepCount",
    "HKCategoryTypeIdentifierSleepAnalysis",
    "HKQuantityTypeIdentifierHeartRate",
    "HKQuantityTypeIdentifierRestingHeartRate",
    "HKQuantityTypeIdentifierHeartRateVariabilitySDNN",
    "HKQuantityTypeIdentifierActiveEnergyBurned",
    "HKCategoryTypeIdentifierAppleStandHour"
  ),
  collapse = "|"
)

records_path <- file.path(tmp_dir, "records.txt")
workouts_path <- file.path(tmp_dir, "workouts.txt")
activity_path <- file.path(tmp_dir, "activity.txt")

message("Pre-filtering export.xml ...")
grep_cmd <- function(pattern, src, dest, fixed = FALSE) {
  flag <- if (fixed) "-F" else "-E"
  status <- system(sprintf(
    "grep %s %s %s > %s",
    flag, shQuote(pattern), shQuote(src), shQuote(dest)
  ))
  invisible(status)
}

grep_cmd(paste0('type="(', record_pattern, ')"'), raw_path, records_path)
grep_cmd("<Workout workoutActivityType", raw_path, workouts_path, fixed = TRUE)
grep_cmd("<ActivitySummary", raw_path, activity_path, fixed = TRUE)

for (p in c(records_path, workouts_path, activity_path)) {
  sz <- if (file.exists(p)) file.info(p)$size else 0
  message("  ", basename(p), ": ", sz, " bytes")
}

workout_type_map <- c(
  HKWorkoutActivityTypeRunning = "Running",
  HKWorkoutActivityTypeWalking = "Walking",
  HKWorkoutActivityTypeCycling = "Cycling",
  HKWorkoutActivityTypeSwimming = "Swimming",
  HKWorkoutActivityTypeFunctionalStrengthTraining = "Strength Training",
  HKWorkoutActivityTypeTraditionalStrengthTraining = "Strength Training",
  HKWorkoutActivityTypeHighIntensityIntervalTraining = "HIIT",
  HKWorkoutActivityTypeYoga = "Yoga",
  HKWorkoutActivityTypeHiking = "Hiking",
  HKWorkoutActivityTypeElliptical = "Elliptical",
  HKWorkoutActivityTypeStairClimbing = "Stair Climbing",
  HKWorkoutActivityTypeRowing = "Rowing",
  HKWorkoutActivityTypeDance = "Dance",
  HKWorkoutActivityTypeCooldown = "Cooldown",
  HKWorkoutActivityTypeOther = "Other"
)

sleep_asleep_values <- c(
  "HKCategoryValueSleepAnalysisAsleep",
  "HKCategoryValueSleepAnalysisAsleepCore",
  "HKCategoryValueSleepAnalysisAsleepDeep",
  "HKCategoryValueSleepAnalysisAsleepREM"
)

extract_attr <- function(line, attr) {
  m <- str_match(line, paste0(attr, '="([^"]*)"'))
  ifelse(is.na(m[, 2]), NA_character_, m[, 2])
}

parse_health_datetime <- function(x) {
  parse_date_time(
    x,
    orders = c("Ymd HMS z", "Ymd HMS", "Ymd HM z", "Ymd HM"),
    tz = "America/New_York"
  )
}

roll_mean <- function(x, k = 7) {
  n <- length(x)
  out <- rep(NA_real_, n)
  for (i in k:n) out[i] <- mean(x[(i - k + 1):i], na.rm = TRUE)
  out
}

parse_records <- function(path) {
  if (!file.exists(path) || file.info(path)$size == 0) {
    return(tibble())
  }
  lines <- read_lines(path, progress = FALSE)
  tibble(
    type = extract_attr(lines, "type"),
    value = suppressWarnings(as.numeric(extract_attr(lines, "value"))),
    value_cat = extract_attr(lines, "value"),
    source_name = extract_attr(lines, "sourceName"),
    start_datetime = parse_health_datetime(extract_attr(lines, "startDate")),
    end_datetime = parse_health_datetime(extract_attr(lines, "endDate"))
  ) %>%
    mutate(
      duration_hours = as.numeric(difftime(end_datetime, start_datetime, units = "hours"))
    ) %>%
    filter(!is.na(start_datetime))
}

parse_workouts <- function(path) {
  if (!file.exists(path) || file.info(path)$size == 0) {
    return(tibble())
  }
  lines <- read_lines(path, progress = FALSE)
  raw_types <- extract_attr(lines, "workoutActivityType")
  tibble(
    workout_type_raw = raw_types,
    workout_type = map_chr(raw_types, function(x) {
      if (is.na(x)) return("Unknown")
      mapped <- unname(workout_type_map[x])
      if (length(mapped) == 1 && !is.na(mapped)) mapped
      else str_remove(x, "^HKWorkoutActivityType")
    }),
    duration_min = as.numeric(extract_attr(lines, "duration")),
    total_distance = as.numeric(extract_attr(lines, "totalDistance")),
    total_distance_unit = extract_attr(lines, "totalDistanceUnit"),
    energy_kcal = as.numeric(extract_attr(lines, "totalEnergyBurned")),
    source_name = extract_attr(lines, "sourceName"),
    start_datetime = parse_health_datetime(extract_attr(lines, "startDate")),
    end_datetime = parse_health_datetime(extract_attr(lines, "endDate"))
  ) %>%
    mutate(
      distance_km = if_else(
        total_distance_unit == "mi",
        total_distance * 1.60934,
        total_distance
      )
    ) %>%
    select(-total_distance, -total_distance_unit)
}

parse_activity <- function(path) {
  if (!file.exists(path) || file.info(path)$size == 0) {
    return(tibble())
  }
  lines <- read_lines(path, progress = FALSE)
  tibble(
    date = as_date(extract_attr(lines, "dateComponents")),
    ring_active_energy = as.numeric(extract_attr(lines, "activeEnergyBurned")),
    ring_active_energy_goal = as.numeric(extract_attr(lines, "activeEnergyBurnedGoal")),
    ring_exercise_min = as.numeric(extract_attr(lines, "appleExerciseTime")),
    ring_exercise_goal = as.numeric(extract_attr(lines, "appleExerciseTimeGoal")),
    ring_stand_hours = as.numeric(extract_attr(lines, "appleStandHours")),
    ring_stand_goal = as.numeric(extract_attr(lines, "appleStandHoursGoal"))
  )
}

message("Parsing filtered records ...")
records <- parse_records(records_path)
workouts <- parse_workouts(workouts_path)
activity_summary <- parse_activity(activity_path)

if (nrow(records) == 0) stop("No matching records found.")

max_date <- max(records$start_datetime, na.rm = TRUE)
min_date <- max_date - years(1)
message("Window: ", as_date(min_date), " to ", as_date(max_date))

records <- records %>% filter(start_datetime >= min_date)
workouts <- workouts %>% filter(start_datetime >= min_date)
activity_summary <- activity_summary %>% filter(date >= as_date(min_date))

sleep_raw <- records %>%
  filter(type == "HKCategoryTypeIdentifierSleepAnalysis") %>%
  mutate(
    sleep_stage = case_when(
      value_cat %in% sleep_asleep_values ~ "Asleep",
      value_cat == "HKCategoryValueSleepAnalysisAwake" ~ "Awake",
      value_cat == "HKCategoryValueSleepAnalysisInBed" ~ "InBed",
      TRUE ~ "Other"
    ),
    wake_date = as_date(end_datetime)
  )

sleep_sessions <- sleep_raw %>%
  filter(sleep_stage %in% c("Asleep", "Awake", "InBed")) %>%
  group_by(wake_date, sleep_stage) %>%
  summarise(duration_hours = sum(duration_hours, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = sleep_stage, values_from = duration_hours, values_fill = 0) %>%
  mutate(
    asleep_hours = coalesce(Asleep, 0),
    awake_hours = coalesce(Awake, 0),
    in_bed_hours = coalesce(InBed, 0)
  ) %>%
  select(wake_date, asleep_hours, awake_hours, in_bed_hours) %>%
  filter(asleep_hours > 0)

summarise_daily <- function(df, value_col, fun) {
  df %>%
    mutate(date = as_date(start_datetime)) %>%
    group_by(date) %>%
    summarise(!!value_col := fun(value, na.rm = TRUE), .groups = "drop")
}

daily_steps <- records %>%
  filter(type == "HKQuantityTypeIdentifierStepCount") %>%
  mutate(date = as_date(start_datetime)) %>%
  group_by(date) %>%
  summarise(steps = sum(value, na.rm = TRUE), .groups = "drop")

daily_energy <- records %>%
  filter(type == "HKQuantityTypeIdentifierActiveEnergyBurned") %>%
  mutate(date = as_date(start_datetime)) %>%
  group_by(date) %>%
  summarise(active_energy_kcal = sum(value, na.rm = TRUE), .groups = "drop")

daily_stand <- records %>%
  filter(type == "HKCategoryTypeIdentifierAppleStandHour") %>%
  mutate(
    date = as_date(start_datetime),
    stood = if_else(value_cat == "HKCategoryValueAppleStandHourStood", 1L, 0L)
  ) %>%
  group_by(date) %>%
  summarise(stand_hours = sum(stood, na.rm = TRUE), .groups = "drop")

daily_hr <- summarise_daily(
  records %>% filter(type == "HKQuantityTypeIdentifierHeartRate"),
  "heart_rate_avg",
  mean
)

daily_resting_hr <- summarise_daily(
  records %>% filter(type == "HKQuantityTypeIdentifierRestingHeartRate"),
  "resting_heart_rate",
  mean
)

daily_hrv <- records %>%
  filter(type == "HKQuantityTypeIdentifierHeartRateVariabilitySDNN") %>%
  mutate(date = as_date(start_datetime)) %>%
  group_by(date) %>%
  summarise(hrv_ms = median(value, na.rm = TRUE), .groups = "drop")

daily_sleep <- sleep_sessions %>%
  rename(date = wake_date, sleep_hours = asleep_hours)

date_seq <- tibble(date = seq(as_date(min_date), as_date(max_date), by = "day"))

daily_summary <- date_seq %>%
  left_join(daily_steps, by = "date") %>%
  left_join(daily_energy, by = "date") %>%
  left_join(daily_stand, by = "date") %>%
  left_join(daily_hr, by = "date") %>%
  left_join(daily_resting_hr, by = "date") %>%
  left_join(daily_hrv, by = "date") %>%
  left_join(daily_sleep, by = "date") %>%
  left_join(activity_summary, by = "date") %>%
  mutate(
    weekday = wday(date, label = TRUE, abbr = FALSE),
    month = floor_date(date, "month"),
    had_workout = date %in% as_date(workouts$start_datetime),
    steps_roll7 = roll_mean(steps, 7),
    sleep_roll7 = roll_mean(sleep_hours, 7),
    active_energy_roll7 = roll_mean(active_energy_kcal, 7)
  )

workouts_out <- workouts %>%
  mutate(
    date = as_date(start_datetime),
    weekday = wday(start_datetime, label = TRUE, abbr = FALSE),
    month = floor_date(start_datetime, "month")
  ) %>%
  select(
    date, weekday, month, workout_type, workout_type_raw,
    duration_min, distance_km, energy_kcal,
    start_datetime, end_datetime, source_name
  )

write_csv(daily_summary, file.path(out_dir, "daily_summary.csv"))
write_csv(sleep_sessions, file.path(out_dir, "sleep_sessions.csv"))
write_csv(workouts_out, file.path(out_dir, "workouts.csv"))

message("Wrote processed CSVs:")
message("  daily_summary: ", nrow(daily_summary), " rows")
message("  sleep_sessions: ", nrow(sleep_sessions), " nights")
message("  workouts: ", nrow(workouts_out), " sessions")
