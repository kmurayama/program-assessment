# Data Sources

Real data files live outside this repo (path set via `ACBSP_DATA_PATH` in
`.Renviron`, not committed) for FERPA compliance. This document describes
their structure so that (a) collaborators know what to expect without
access to the real files, and (b) synthetic stand-ins can be generated to
match the real schema.

Each source below is read by [R/int_read.R](../R/int_read.R) or
[R/report-internal-direct-2019.R](../R/report-internal-direct-2019.R).
For each column: type, example value, and any notes on valid values,
quirks, or typos the munging code corrects for. PII/sensitivity status is
noted per file/sheet above each table, not per column.

---

## Rubrics.xlsx

Path: `<ACBSP_DATA_PATH>/Rubrics.xlsx`
Sheet: Rubrics
FERPA: PII contained

One row per (student, assessment, rubric criterion). Note that this is a
configuration for 2019 round and the format can change drastically in the future
round.

| Column | Type | Example | Notes |
|---|---|---|---|
| RubricId | factor | 111740 | Read as factor. Matches the `rubricId=` URL param joined from the survey. |
| UserId | factor | 123456 | Read as factor. Uniquely identify students. |
| Name | factor | PLO 3 Information literacy | Criterion name, e.g. "Citations", "Major", "Level 0"-scored criteria. Read as factor. It may contain students' atrributes like majors and minors. |
| Score | numeric | 4.25 | Assessment score. Read as a numeric value. Note that the maximum values are not indicated. |
| LevelAchieved | factor | Good 85% | Free text; values like "Proficient", "Level 2", or a typo "Unsatisactory (<60%)" — see [int_munge.R](../R/int_munge.R). |
| Feedback | text | You chose a good source. | Free text. Mostly empty. |
| IsScoreOverridden | logical | False | "True"/"False" string, coerced to logical. |

---

## Assessment Survey Responses.xlsx

Path: `<ACBSP_DATA_PATH>/Assessment Survey Responses.xlsx`
Sheet: `Edited`
One row per instructor-submitted assessment survey response. Column
names in the raw file are full question text; matched by prefix against
[R/survey_colnames.csv](../R/survey_colnames.csv) and renamed. Note this
includes instructor name/email, which is why the sample below was pulled
filtered to the author's own rows only rather than shared unfiltered.

| short_name (post-rename) | Type | Example | Notes |
|---|---|---|---|
| ID | numeric | 35 | Survey response ID. |
| Drop | logical | FALSE | Boolean-ish; rows with `Drop` are excluded. Indicate the survey response that are void for some reasons. |
| Start | time | 5/11/20 18:04:08 | Timestamp |
| Complete | time | 5/11/20 18:35:18 | Timestamp |
| Email | text | smith@calu.edu | Instructor email — real but identifies a person; anonymize in synthetic data even though not student data. |
| Instructor | text | John Smith | Instructor name — same caveat as Email. |
| Semester | factor | Fall 2019 | Semester and year such as Spring 2020 / Fall 2019 |
| Course.Section.Original | factor | ECO 421 - 001 | Raw combined course+section as originally entered. |
| Course | factor | ECO 421 | Course identifier. e.g. "ECO 201", "BUS 499" |
| Section | factor | ECO 421 001 | Section identifier. "GW" substring flags an online section. |
| Assessment.Original | text | Term Project | Original entries for the assessment name. May contain typos. |
| Assessment | text | Term Project | Assessment names after standardization. |
| Follow up | text | No data? | Comments used while tracking the survey answers. |
| Rubric | factor | Yes | "Yes"/"No" — splits rows into rubric vs non-rubric data. |
| URL | text | https://calu.desire2learn.edu/... | Contains `rubricId=######` extracted via regex. |
| Analysis.Rubric | text | "Students have..." | Free text. Analysis of the rubric outcomes by the instructor. |
| Action.Rubric | text | "Good outcomes in..." | Free text. Analysis of the potential actions by the instructor. |
| PLO.Original | text | Economics PLO 3, 4, 5 | PLO entries by the instructors. Highly variable. |
| PLO | text | ECO 3, ECO 4, ECO 5 | PLO entries standardized. |
| n.original | numeric | 35 | Total number of students. |
| n | numeric | 35 | Total number of students, typo fixed. |
| np.original | numeric | 33 | Total number of students who passed the grade threashold. |
| np | numeric | 33 | Total number of students who passed the grade threashold, typo fixed. |
| Analysis.Non.Rubric | text | "Students have..." | Free text. Analysis of the non-rubric outcomes by the instructor. |
| Action.Non.Rubric | text | "Good outcomes in..." | Free text. Analysis of the potential actions by the instructor for non-rubric assessments. |

---

## Assessment Data Main.xlsx

Path: `<ACBSP_DATA_PATH>/Assessment Data Main.xlsx`
Sheets: `prg`, `core`, `mba` (data) and `map_prg`, `map_core`, `map_mba` (mappings)

### Data sheets: `prg` / `core` / `mba`

Contains historical data of the assessment outcomes through 2016-2018 academic
years for comparison. Confirmed from `core` — assume `prg`/`mba` share the
same shape unless checked otherwise.

| Column | Type | Example | Notes |
|---|---|---|---|
| ID | factor | Business Core-BUS 1-Summative-External-2016 | `{program}-{plo}-{type}-{source}-{ay}` composite key. Note: `map_*` sheets key on `plo_id` (no year), this sheet keys on `ID` (with year) — not directly joinable as-is. |
| program | factor | Business | Program names like marketing, accounting, etc. |
| plo | factor | BUS 1 | Program Learning Objectives (PLO) |
| type | factor | Summative | Type of assessment. Summative or Formative. |
| source | factor | External | Source of assessment. External (e.g., standard test) or internal (e.g., rubric-based assessments) |
| ay | factor | 2016 | Academic year. |
| main_n | numeric | 140 | Overall n for the PLO/year. |
| main_outcome | numeric | 57% | Overall outcome rate. Share of students who passed the pre-set threashold. |
| acc_outcome / eco_outcome / fin_outcome / hrm_outcome / bus_outcome / mgt_outcome / mis_outcome / mkt_outcome | | 70% / 51% / 61% / 52% / 55% / 53% / 61% / 55% | Outcome disaggregated by major (Accounting, Economics, Finance, HRM, Business, Management, MIS, Marketing) — same disaggregation idea as the `Major` breakout in [report-internal-direct-2019.R](../R/report-internal-direct-2019.R), but precomputed here for historical years. |
| acc_n / eco_n / fin_n / hrm_n / bus_n / mgt_n / mis_n / mkt_n | | 24 / 6 / 16 / 20 / 6 / 35 / 5 / 28 | n per major, paired with the `*_outcome` columns above. |

### Mapping sheets: `map_prg` / `map_core` / `map_mba`

One row per PLO x assessment-type combination (e.g. "ACC 1-Summative-Internal").
Confirmed from `map_prg` — assume `map_core`/`map_mba` share the same shape
unless checked otherwise.

| Column | Type | Example | Notes |
|---|---|---|---|
| plo_id | factor | ECO 4-Formative-Internal | `{plo}-{type}-{source}` composite key. |
| program | factor | Economics | Program names like marketing, accounting, etc. |
| plo | factor | ECO 4 | Program Learning Objectives. Output PLO label written to `tbl_assess`/`out` in the report script. |
| type | factor | Formative | Type of assessment. Summative or Formative. |
| source | factor | Internal | Source of assessment. External (e.g., standard test) or internal (e.g., rubric-based assessments) |
| group1 | factor | Course | Grouping of assessment types for data aggregation such as Course or All. |
| group2 | factor | ECO 421 | Grouping of assessment types for data aggregation such as ECO 421. |
| tool_description | text | A semester-long project which involves... | Free text. Description of the assessment tool. |
| unit | text | Prevalence (Ach 70% of students...) | Unit of measurements for achievement. |
| goal_target_description | text | 70% of students will... | Target level of the achievement. |
| goal | numeric | 70% | Threashold for achievement (Met/Not Met). |
| target | numeric | 70% | Target share of stduents who reach the threashold. |
| external_reference_group | factor | NA | Grouping rule of students to compare against. |
| internal_rubric_tags | text | ECO 3, ECO 4, ECO 5 | Tags used to identify the rubric rows that correspond to each PLO. |
| internal_rubric_keys2019 | text | Literature Review | Regex matched against rubric criterion `Name` based on the `internal_rubric_tags`. For 2019 round. |
| internal_rubric_keys2020 | text | Literature Review | Regex matched against rubric criterion `Name` based on the `internal_rubric_tags`. For 2020 round. |

---

## D2L Missing Data Retrievals.xlsx

Path: `<ACBSP_DATA_PATH>/D2L Missing Data Retrievals.xlsx`
Sheet: `Scraped`
Manually-collected backfill for assessments missing from the rubric
export; unioned with the summarized rubric data so it must share the
same column set after read. One row per (course, section, semester,
assessment, criterion) — pre-aggregated across students, unlike
`Rubrics.xlsx` which is one row per student.

| Column | Type | Example | Notes |
|---|---|---|---|
| Course | factor | ECO 421 | |
| Section | factor | ECO 421 001 | |
| Semester | factor | Fall 2019 | |
| Assessment | text | Term Project | (Truncated in sample as "Term Projec".) |
| Name | text | Introduction | Rubric criterion name — matches `Name` in `Rubrics.xlsx`. |
| Unsatisfactory | numeric | 0 | Count of students scoring this level. |
| Developing | numeric | 0-2 | Count of students scoring this level. |
| Basic | numeric | 1-6 | Count of students scoring this level. |
| Proficient | numeric | 2-6 | Count of students scoring this level. |
| Advanced | numeric | 1-4 | Count of students scoring this level. |
| Met | numeric | 0.82-1.00 | Precomputed proportion "met" or the students who passed the threashold level of achievements set in `Assessment Data Main.xlsx`; copied into both `Met.UND` and `Met.GRD` on read. |
| n | numeric | 11 | Total students; sum of the five level counts. |
| PLO | factor | ECO 3, ECO 4, ECO 5 | Comma-separated list, matching survey `PLO` format. |

---

## Synthetic data

[data-raw/make_synthetic.R](../data-raw/make_synthetic.R) generates small
stand-in `.xlsx` files for the four sources above (2 programs, 4 courses,
~40 students total) and writes them to
`data/synthetic/AY2019/Internal Direct Assessment/`. The folder does not need
to reproduce incidental words such as `Backup` from the real storage layout;
the pipeline uses `ACBSP_DATA_PATH` as the directory containing the four input
workbooks. The generated synthetic files are safe to commit. Run
`Rscript data-raw/make_synthetic.R` (requires the `writexl` package) to refresh
them.

To run `R/int_read.R` → `R/int_munge.R` → `R/report-internal-direct-
2019.R` against it: after generating the files above, copy
[.Renviron.example](../.Renviron.example) to `.Renviron` (gitignored)—it
already points `ACBSP_DATA_PATH` at the synthetic workbook directory.

Deliberately reproduces the real quirks the munging code handles, so the
demo actually exercises the interesting logic instead of running on inert
data:

- The `"Unsatisactory (<60%)"` typo and the `"Level N"` achievement scale,
  alongside the normal word scale (both wordings — see
  `int_munge.R`'s `achievements1`/`achievements2`).
- ECO 201 vs ECO 202 criterion-name correction (`"Citations"`/`"Structure"`
  resolve differently per course).
- A `"GW"` online section (`ECO 202 GW1`).
- `Major`/`Minor` attribute rows for BUS 499, including a `"General
  Business"` value that should collapse to `"ISBC"`.
- A stray `"New Criterion"` row with no score (dropped).
- A `RubricId` with no matching survey response (exercises the merge-
  coverage message).
- A non-rubric (`Rubric == "No"`) survey response and a `Drop == TRUE`
  response.
- A `D2L Missing Data Retrievals.xlsx` row for a course/section that never
  appears in Rubrics.xlsx/the survey, proving the backfill union actually
  adds rows.

Out of scope: `R/report-external-direct-2019.R` reads different,
undocumented source files via a hardcoded path and isn't covered here.
