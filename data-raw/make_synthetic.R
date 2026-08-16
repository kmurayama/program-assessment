# ==============================================================================
# Script Name: make_synthetic.R
# Purpose: Generate small synthetic stand-ins for the real (FERPA-protected)
#   AY2019 Internal Direct Assessment data files, matching the schema
#   documented in data/README.md, so R/int_read.R -> R/int_munge.R ->
#   R/report-internal-direct-2019.R can run end-to-end without access to
#   real student data.
# Notes: Deliberately reproduces the real quirks the munging code handles:
#   the "Unsatisactory" typo, the "Level N" achievement scale, mixed
#   achievement-scale wording, ECO 201/202 criterion-name corrections,
#   GW online-section detection, Major/Minor attribute rows (incl. the
#   ISBC name collapse), a stray "New Criterion" row, an orphan RubricId
#   with no survey match, and a D2L backfill row for a course missing from
#   the rubric export.
# ==============================================================================

library(tidyverse)
library(writexl)

set.seed(20190821)

out_dir <- file.path("data", "synthetic", "AY2019 Backup",
                      "Internal Direct Assessment")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# ---- shared vocab -----------------------------------------------------------

# Rubrics on D2L use either word-scale convention (or, rarely, "Level N").
# int_munge.R normalizes all of them - mix them here so that logic is
# actually exercised, the way it would be against real data.
level_pool <- c("Unsatisfactory", "Developing", "Basic", "Proficient", "Advanced",
                "Unacceptable", "Rudimentary (<70%)", "Fair", "Good (85%)", "Excellent")

sample_levels <- function(n) sample(level_pool, n, replace = TRUE)

# ==============================================================================
# Rubrics.xlsx
# ==============================================================================

make_criterion_rows <- function(rubric_id, user_ids, criteria) {
  crossing(RubricId = rubric_id, UserId = user_ids, Name = criteria) %>%
    mutate(Score = round(runif(n(), 1, 5), 2),
           LevelAchieved = sample_levels(n()),
           Feedback = "",
           IsScoreOverridden = "False")
}

eco201_users <- 1001:1010
eco202_users <- 2001:2010
eco421_users <- 3001:3012
bus499_users <- 4001:4010

rub_eco201 <- make_criterion_rows(
  100001, eco201_users,
  c("Citations", "Structure", "Arguments For Protection", "Winners/Losers"))

rub_eco202 <- make_criterion_rows(
  100002, eco202_users,
  c("Data Collection", "Time-Series Graphs", "Citations", "Structure"))

rub_eco421 <- make_criterion_rows(
  100003, eco421_users,
  c("Introduction", "Literature Review",
    "Description Of Data and Empirical Model", "Discussion Of Empirical Results"))

rub_bus499 <- make_criterion_rows(
  100004, bus499_users,
  c("Plo2 Written Communication", "Plo7 Ethical Reasoning"))

# Orphan RubricId: no matching survey response (exercises the merge-coverage
# message in int_read.R).
rub_orphan <- make_criterion_rows(100005, 5001:5002, c("Final Exam"))

# Major/Minor attribute rows for BUS 499 (not achievement scores - excluded
# from the achievement regex by `attribute_criteria` in int_munge.R). Half
# the class reports a major name that should collapse to "ISBC".
major_choice <- rep(c("General Business", "Accounting"), length.out = length(bus499_users))
bus499_attrs <- bind_rows(
  tibble(RubricId = 100004, UserId = bus499_users, Name = "Major",
         Score = NA_real_, LevelAchieved = major_choice, Feedback = "",
         IsScoreOverridden = "False"),
  tibble(RubricId = 100004, UserId = bus499_users, Name = "Minor",
         Score = NA_real_, LevelAchieved = "None", Feedback = "",
         IsScoreOverridden = "False")
)

# Deliberate quirks: the typo, and the numeric "Level N" scale.
rub_eco201$LevelAchieved[1] <- "Unsatisactory (<60%)"
rub_bus499$LevelAchieved[2] <- "Level 2"

# Stray "New Criterion" row with no score yet (dropped by int_munge.R).
new_criterion_row <- tibble(RubricId = 100003, UserId = eco421_users[1],
                             Name = "New Criterion", Score = NA_real_,
                             LevelAchieved = NA_character_, Feedback = "",
                             IsScoreOverridden = "False")

rubrics <- bind_rows(rub_eco201, rub_eco202, rub_eco421, rub_bus499,
                      rub_orphan, bus499_attrs, new_criterion_row)

write_xlsx(list(Rubrics = rubrics), file.path(out_dir, "Rubrics.xlsx"))

# ==============================================================================
# Assessment Survey Responses.xlsx
# ==============================================================================

# Column headers must each START WITH the matching prefix in
# R/survey_colnames.csv (matched positionally), so use full question-style
# text built from those prefixes.
survey_headers <- c(
  "ID", "Drop", "Start time", "Completion time", "Email", "Name",
  "In which semester did you administer this assessment?",
  "Course AND Section (e.g., ECO 201-001)", "Course", "Section",
  "What is the name of the assessment?", "Assessment (standardized)",
  "Follow up notes", "I graded this assessment using a rubric",
  "Copy and paste the rubric URL here",
  "Analysis of the rubric-based outcomes", "Action for improvement (rubric)",
  "What is the PLO addressed (as entered)?", "PLO",
  "What is n, the total number of students?", "n",
  "If this is an undergraduate course, how many students passed?", "np",
  "Analysis of the non-rubric outcomes",
  "Action for improvement (non-rubric)")

rubric_url <- function(rubric_id) {
  sprintf("https://calu.desire2learn.edu/d2l/lms/rubrics/rubrics_manage.d2l?ou=6606&rubricId=%d&isPopup=1", rubric_id)
}

survey_rows <- tribble(
  ~ID, ~Drop, ~Start,               ~Complete,            ~Email,              ~Instructor,      ~Semester,    ~Course.Section.Original, ~Course,   ~Section,        ~Assessment.Original,   ~Assessment,           ~`Follow up`, ~Rubric, ~URL,                    ~Analysis.Rubric,          ~Action.Rubric,             ~PLO.Original,              ~PLO,                  ~n.original, ~n, ~np.original, ~np, ~Analysis.Non.Rubric,        ~Action.Non.Rubric,
  1,   FALSE, "5/11/2020 18:04:08", "5/11/2020 18:35:18", "smith@calu.edu",    "John Smith",     "Fall 2019",  "ECO 201 - 001",          "ECO 201", "ECO 201 001",   "Policy Analysis Papers", "Policy Analysis Paper", "",           "Yes",   rubric_url(100001),      "Students showed solid grasp of the policy tradeoffs.", "Add more in-class citation practice.", "Economics PLO 1",           "ECO 1",               10,          10, 8,            8,   NA_character_,               NA_character_,
  2,   FALSE, "5/8/2020 9:12:00",   "5/8/2020 9:40:00",   "lee@calu.edu",      "Jane Lee",       "Spring 2020","ECO 202 - GW1",          "ECO 202", "ECO 202 GW1",   "Macro Data Project",     "Macro Data Project",    "",           "Yes",   rubric_url(100002),      "Online section performed comparably to in-person.",     "Revise time-series graphing instructions.", "Economics PLO 2",           "ECO 2",               10,          10, 9,            9,   NA_character_,               NA_character_,
  3,   FALSE, "12/14/2019 14:20:00","12/14/2019 15:05:00","garcia@calu.edu",   "Maria Garcia",   "Fall 2019",  "ECO 421 - 001",          "ECO 421", "ECO 421 001",   "Term Project",           "Term Project",          "",           "Yes",   rubric_url(100003),      "Students have generally strong literature review skills.", "Discuss empirical results in more depth.", "Economics PLO 3, 4, 5",     "ECO 3, ECO 4, ECO 5", 12,          12, 10,           10,  NA_character_,               NA_character_,
  4,   FALSE, "5/20/2020 10:00:00", "5/20/2020 10:45:00", "chen@calu.edu",     "Robert Chen",    "Spring 2020","BUS 499 - 001",          "BUS 499", "BUS 499 001",   "Capstone Project",       "Capstone Project",      "",           "Yes",   rubric_url(100004),      "Good outcomes in written communication across majors.",  "Add an ethics case study earlier in the term.", "Business PLO 2, 7",  "BUS 2, BUS 7",        10,          10, 9,            9,   NA_character_,               NA_character_,
  5,   FALSE, "12/10/2019 8:30:00", "12/10/2019 8:50:00", "smith@calu.edu",    "John Smith",     "Fall 2019",  "ECO 201 - 001",          "ECO 201", "ECO 201 001",   NA_character_,            NA_character_,           "No data?",   "No",    NA_character_,           NA_character_,             NA_character_,             "Economics PLO 1",           "ECO 1",               20,          20, 17,           17,  "Students have participated actively all semester.", "Good outcomes in class discussion; no action needed.",
  6,   TRUE,  "12/11/2019 8:00:00", "12/11/2019 8:05:00", "garcia@calu.edu",   "Maria Garcia",   "Fall 2019",  "ECO 421 - 001",          "ECO 421", "ECO 421 001",   "Term Project",           "Term Project",          "Duplicate submission - void", "Yes", rubric_url(100003), NA_character_,             NA_character_,             "Economics PLO 3, 4, 5",     "ECO 3, ECO 4, ECO 5", 12,          12, 10,           10,  NA_character_,               NA_character_
)

survey_out <- survey_rows
names(survey_out) <- survey_headers

write_xlsx(list(Edited = survey_out),
           file.path(out_dir, "Assessment Survey Responses.xlsx"))

# ==============================================================================
# Assessment Data Main.xlsx
# ==============================================================================

# Historical data sheets (prg/core/mba): read but unused downstream by
# report-internal-direct-2019.R - stub rows matching the documented schema
# are enough so the unconditional read at the top of that script succeeds.
make_data_stub <- function(id, program, plo, type) {
  tibble(ID = id, program = program, plo = plo, type = type, source = "External",
         ay = 2018, main_n = 100, main_outcome = "60%",
         acc_outcome = "60%", eco_outcome = "60%", fin_outcome = "60%",
         hrm_outcome = "60%", bus_outcome = "60%", mgt_outcome = "60%",
         mis_outcome = "60%", mkt_outcome = "60%",
         acc_n = 10, eco_n = 10, fin_n = 10, hrm_n = 10, bus_n = 10,
         mgt_n = 10, mis_n = 10, mkt_n = 10)
}
data_prg <- make_data_stub("Accounting-ACC 1-Summative-External-2018", "Accounting", "ACC 1", "Summative")
data_core <- make_data_stub("Business Core-BUS 1-Summative-External-2018", "Business", "BUS 1", "Summative")
data_mba <- make_data_stub("MBA-MBA 1-Summative-External-2018", "MBA", "MBA 1", "Summative")

# Mapping sheets (map_prg/map_core/map_mba): drive report-internal-direct-
# 2019.R's Course-based aggregation. group1 == "Course" is required for a
# row to be picked up; map_core needs at least one such row purely to avoid
# an empty-dataframe `1:nrow()` indexing crash (nrow=0 -> `1:0` -> out-of-
# bounds tibble row), even though that particular result is never written
# to file by the report script.
map_prg <- tribble(
  ~plo_id,                     ~program,     ~plo,    ~type,        ~source,    ~group1,  ~group2,   ~tool_description,                         ~unit,                              ~goal_target_description, ~goal, ~target, ~external_reference_group, ~internal_rubric_tags,   ~internal_rubric_keys2019,          ~internal_rubric_keys2020,
  "ECO 3-Summative-Internal",  "Economics",  "ECO 3", "Summative",  "Internal", "Course", "ECO 421", "A semester-long project which involves...", "Prevalence (Ach 70% of students)", "70% of students will...", "70%", "70%",   "NA",                      "ECO 3, ECO 4, ECO 5",   ".*",                                ".*",
  "ECO 4-Formative-Internal",  "Economics",  "ECO 4", "Formative",  "Internal", "Course", "ECO 421", "A semester-long project which involves...", "Prevalence (Ach 70% of students)", "70% of students will...", "70%", "70%",   "NA",                      "ECO 3, ECO 4, ECO 5",   "Literature Review",                "Literature Review",
  "ECO 5-Formative-Internal",  "Economics",  "ECO 5", "Formative",  "Internal", "Course", "ECO 421", "A semester-long project which involves...", "Prevalence (Ach 70% of students)", "70% of students will...", "70%", "70%",   "NA",                      "ECO 3, ECO 4, ECO 5",   "Discussion Of Empirical Results",  "Discussion Of Empirical Results",
  "ACC 3-Summative-Internal",  "Accounting", "ACC 3", "Summative",  "Internal", "Course", "ACC 202", "Backfilled from D2L Missing Data Retrievals.", "Prevalence (Ach 70% of students)", "70% of students will...", "70%", "70%",   "NA",                      "ACC 3",                 ".*",                                ".*"
)

map_core <- tribble(
  ~plo_id,                    ~program,   ~plo,    ~type,       ~source,    ~group1,  ~group2,   ~tool_description,                          ~unit,                              ~goal_target_description, ~goal, ~target, ~external_reference_group, ~internal_rubric_tags, ~internal_rubric_keys2019, ~internal_rubric_keys2020,
  "BUS 1-Summative-Internal", "Business", "BUS 1", "Summative", "Internal", "Course", "BUS 499", "Placeholder - not used by the internal report.", "Prevalence (Ach 70% of students)", "70% of students will...", "70%", "70%",   "NA",                      "BUS 1",               ".*",                      ".*"
)

map_mba <- map_core[0, ]  # unused by the internal report; header-only is fine

write_xlsx(
  list(prg = data_prg, core = data_core, mba = data_mba,
       map_prg = map_prg, map_core = map_core, map_mba = map_mba),
  file.path(out_dir, "Assessment Data Main.xlsx"))

# ==============================================================================
# D2L Missing Data Retrievals.xlsx
# ==============================================================================

# A course/section that never made it into Rubrics.xlsx/the survey at all -
# proves the bind_rows() backfill path in report-internal-direct-2019.R adds
# rows rather than duplicating existing ones. PLO matches the ACC 3 row in
# map_prg above so it flows through to prg_internal.csv.
d2l_missing <- tribble(
  ~Course,   ~Section,      ~Semester,     ~Assessment,  ~Name,             ~Unsatisfactory, ~Developing, ~Basic, ~Proficient, ~Advanced, ~Met, ~n, ~PLO,
  "ACC 202", "ACC 202 001", "Spring 2020", "Case Study", "Ethics Analysis", 0,               1,           2,      4,           3,         0.9,  10, "ACC 3"
)

write_xlsx(list(Scraped = d2l_missing),
           file.path(out_dir, "D2L Missing Data Retrievals.xlsx"))

message("Synthetic data written to: ", out_dir)
