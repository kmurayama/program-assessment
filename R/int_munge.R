# ==============================================================================
# Script Name: init_munge.R
# Purpose: Clean up and standardize the data created in int_read.R
# Author: Kentaro Murayama (km7813a@gmail.com)
# Date Created: 
# Notes: Run after int_read.R as it assumes the data frames inherited.
# ==============================================================================

### ---- fix-rubric-row-names ----
pttrn.eco201.n <- c("^Arguments For Protection$"="Arguments For Protectionism",
                    "^Citations$"="Citations/References",
                    "^Structure$"="Structure/Clarity",
                    "^Winners/Losers$"="Winners And Losers",
                    "^Writing: Citations$"="Writing: Citations/References")
pttrn.eco202.n <- 
  c("^Data Collection$" = "Part 1: Data Collection",
    "^Time-Series Graphs$" = "Part 1: Time Series Plots",
    "^Explain Variable Movements$" = "Part 2: Explain Variable Movements",
    "^Short-Run And Long-Run Perspectives$" = "Part 2: Short-Run And Long-Run Perspectives",
    "^Compare And Contrast$" = "Part 2: Compare And Contrast",
    "^Citations$" = "Writing: Citations",
    "^Grammar$" = "Writing: Grammar",
    "^Structure$" = "Writing: Structure")

mdf <- mdf %>%
  mutate(Name = str_to_title(str_remove(Name, '^"')),
         # "Citations" and "Structure" mean different things (and get different
         # corrected labels) in ECO201 vs ECO202
         Name = if_else(coalesce(str_detect(Course, "^ECO[ -]?201$"), FALSE),
                         str_replace_all(Name, pttrn.eco201.n), Name),
         Name = if_else(coalesce(str_detect(Course, "^ECO[ -]?202$"), FALSE),
                         str_replace_all(Name, pttrn.eco202.n), Name),
         # "Major/Concentration" and "Minor/Certificate" are trivial variants
         # of "Major"/"Minor" - collapse to one canonical name each.
         Name = recode(Name, "Major/Concentration" = "Major",
                              "Minor/Certificate" = "Minor"))

### ---- standardize-achievement ----
mdf$LevelAchieved.Original <- mdf$LevelAchieved
mdf$LevelAchieved <-
  str_replace_all(mdf$LevelAchieved,
                  fixed("Unsatisactory (<60%)"), "Unsatisfactory") # Fix a typo

achievements1 <- c("Unsatisfactory", "Developing", "Basic", "Proficient", "Advanced")
achievements2 <- c("Unacceptable", "Rudimentary", "Fair", "Good", "Excellent")
names(achievements2) <- achievements1 # Named list as dictionary

# Some rubric criteria (Analysis, Calculation, Information Analysis,
# Information Collection, and the "Student ..." criteria) score on a
# "Level 0"-"Level 4" scale instead of the Unsatisfactory...Advanced wording.
achievements.level <- setNames(achievements1, paste("Level", 0:4)) # "Level N" -> achievements1 label

pttrn <- paste(c(achievements1, achievements2, names(achievements.level)), collapse = "|")

mdf <- mdf %>% mutate(
  LevelAchieved = str_extract(mdf$LevelAchieved, pttrn))

# Rows for these criteria capture demographic/attribute info (major, minor,
# etc.), not an achievement score.
attribute_criteria <- c("Major", "Minor", "New Criterion")

# Catch unexpected levels in LevelAchieved
# Compare the original and new columns - new NA indicates a mismatch. Group
# by criterion Name (with counts) so it's clear at a glance whether this is
# a mistake/stray criterion to add to attribute_criteria, or a genuine new
# achievement-scale wording to add to achievements1/achievements2/
# achievements.level - no need to separately re-run a cross-tab to decide.
unmapped <- mdf %>%
  filter(is.na(LevelAchieved), !is.na(LevelAchieved.Original),
         !Name %in% attribute_criteria) %>%
  count(Name, LevelAchieved.Original)
if (nrow(unmapped) > 0) {
  msg <- unmapped %>%
    group_by(Name) %>%
    summarise(detail = paste0(LevelAchieved.Original, " (", n, ")", collapse = ", ")) %>%
    mutate(line = paste0(Name, ": ", detail)) %>%
    pull(line) %>%
    paste(collapse = "\n")
  stop("Unrecognized LevelAchieved value(s) - decide whether to add each to ",
       "achievements1/achievements2/achievements.level (new scale wording) or ",
       "attribute_criteria (not an achievement measure):\n", msg)
}

# "New Criterion" is a stray rubric row. Drop it so downstream reports don't
# need to remember to filter it out themselves. Guarded on LevelAchieved being
# NA (not just the Name) so a future year's "New Criterion" that does contain a
# real, recognized score is kept rather than silently discarded.
mdf <- mdf %>% filter(!(Name == "New Criterion" & is.na(LevelAchieved)))

mdf$LevelAchieved <- str_replace_all(mdf$LevelAchieved, achievements.level) # "Level N" -> achievements1 label
mdf$LevelAchieved <- str_replace_all(mdf$LevelAchieved, achievements2)
mdf$LevelAchieved <- ordered(mdf$LevelAchieved, levels = achievements2)

## ---- new-variables ----
mdf <- mdf %>% mutate(
  Met.UND = case_when(
    is.na(LevelAchieved) ~ "Missing",
    LevelAchieved == "Excellent" | LevelAchieved == "Good" |
      LevelAchieved == "Fair" ~ "Met",
    LevelAchieved == "Rudimentary" | LevelAchieved == "Unacceptable" ~ "Not"),
  Met.GRD = case_when(
    is.na(LevelAchieved) ~ "Missing",
    LevelAchieved == "Excellent" | LevelAchieved == "Good" ~ "Met",
    LevelAchieved == "Fair" | LevelAchieved == "Rudimentary" |
      LevelAchieved == "Unacceptable" ~ "Not"),
  Online = grepl("GW", Section),  # Online sections has GW in section ID
  Met.UND.bin = Met.UND == "Met",
  Met.GRD.bin = Met.GRD == "Met"
  )

