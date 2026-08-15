# Case Study: Program Assessment Reporting

> **Data note:** the original project ran on confidential student and
> instructor records that can't be shared publicly. Everything in this
> repository, including the figure below, runs on a small synthetic
> dataset built to reproduce the real data's structure and quirks —
> not its actual values. Where this case study describes the real
> project's outputs, it does so in general terms, without institution
> names or real outcome numbers.

## Background

Business schools accredited by ACBSP (the field's accrediting body) must
report what share of students met a proficiency threshold for each
program learning outcome (PLO) — a specific skill the degree is supposed
to teach, like written communication or ethical reasoning. Instructors
supply the raw material: rubric scores they enter in the school's course
software, plus a short survey filled out per assessment. Before this
project, that report was built by hand in Excel each cycle, and the
rubrics themselves weren't standardized — so even the manual version
couldn't reliably compare one year to the next.

I led that standardization as committee chair: working with a
department-wide committee over three annual cycles of evaluation and
revision, we moved the program onto a common, rubric-based assessment
scheme. This repo is the analyst-side counterpart I built solo — code
that turns the raw exports that scheme produces into the standardized
outcome tables accreditation requires.

The scripted pipeline mattered most for continuity. Rubric-based,
transparent assessment was a real cultural shift for the department, and
a reproducible pipeline is what let that shift outlive any one person
running it — the code, not institutional memory, carries the standard
forward. That mattered in practice: the framework survived a later
merger with two other schools, was adopted by the newly formed
department, and the underlying assessment work was presented at an
accreditation-body conference and received an award. Beyond continuity,
it also improved accuracy (accreditation depends on defensible,
transparent numbers) and cut the time cost of each reporting cycle.

## The problem: messy real-world data

The raw exports were never designed to be analyzed — they were designed
to be filled out quickly by instructors under time pressure. That shows:

| Raw-data problem | Analytical consequence | Resolution |
|---|---|---|
| Achievement recorded on several different wordings/scales ("Good (85%)" vs. "Proficient" vs. "Level 3") | Scores aren't comparable across rubrics without translation | Mapped every variant onto one ordered scale (`int_munge.R`) |
| A recurring typo in one scale value | A student's actual level goes unrecognized, silently dropped as missing | Corrected before scale-mapping, with a check that fails loudly on any *new* unrecognized value |
| Same criterion name means different things in different courses (e.g. "Citations" graded differently in two economics courses) | Naively grouping by criterion name conflates unrelated measures | Course-conditional renaming before aggregation |
| Some course sections' rubric data never made it into the main export | Those students would be silently excluded from the outcome rate | A separately-tracked backfill file is merged in, with row counts checked so gaps are visible rather than silent |
| Rows for student major/minor mixed in with actual score rows | Naive averaging would treat attributes as if they were scores | Explicitly flagged and excluded criteria (`Major`, `Minor`, stray placeholder rows) |

A small illustration, built from the synthetic data this repo ships with:

```
Raw rubric row
RubricId | UserId | Name              | Score | LevelAchieved
100001   | 1001   | Citations         | 3.50  | Unsatisactory (<60%)   <- typo
100004   | 4001   | Major             | NA    | General Business       <- not a score

Cleaned analytical row
RubricId | UserId | Name                      | LevelAchieved | Met.UND
100001   | 1001   | Citations/References      | Unsatisfactory | Not
100004   | 4001   | (excluded - attribute row, not an outcome measure)
```

## What I did

The pipeline is read → standardize → aggregate, but the interesting part
is the judgment calls inside each step, not the mechanics:

1. **`R/int_read.R`** reads the rubric export and the instructor survey
   and merges them — deciding, for instance, how to handle rubric IDs
   with no matching survey response rather than silently dropping them.
2. **`R/int_munge.R`** is where most of the real analysis happens:
   deciding which wording variants are the same underlying scale value,
   which criterion-name collisions need course-specific disambiguation,
   and which rows are attributes rather than scores. Every new,
   unrecognized value stops the pipeline with a message telling you
   exactly which criterion and value to triage — a deliberate design
   choice so that data-quality problems get decided by a person once,
   not silently mis-scored forever.
3. **`R/report-internal-direct-2019.R`** aggregates cleaned,
   student-level rows up through section and course to the PLO level,
   using a mapping that ties specific rubric criteria to specific
   learning outcomes.

## How the outcome categories emerged

The mapping in step 3 above — which rubric criteria count toward which
PLO — wasn't decided once and frozen. The repo's data schema
(`data/README.md`) documents two separate mapping columns for
consecutive years (`internal_rubric_keys2019`, `internal_rubric_keys2020`):
the criteria that were judged to represent a given outcome changed
between cycles, as exploratory review of score distributions and rubric
wording surfaced criteria that didn't cleanly represent what they were
assumed to. That's the norm for this kind of project, not an exception:
the measurement structure was as much an output of the analysis as the
outcome numbers were, and keeping both years' mappings in the schema
(rather than overwriting one with the other) preserves that history
instead of hiding it.

## Original project outputs

The live version of this pipeline fed an annual outcomes report reviewed
by the accreditation committee. That report used three views built from
the same cleaned data this repo produces:

- **Trends over time** — outcome rate per PLO across academic years,
  against the target threshold.
- **Internal vs. external comparison** — since the same PLO is often
  measured two ways (an internal rubric and an external standardized
  exam), plotting one against the other made agreement or divergence
  between the two instruments visible at a glance.
- **Snapshot vs. target** — how far each PLO stood from its target in
  the most recent cycle, used to flag outcomes needing attention.

Because those figures show real, small-sample program performance,
they aren't reproduced here. The chart below is the same first view —
outcome rate per PLO against target — generated by
[`R/plot_outcomes.R`](../R/plot_outcomes.R) from the synthetic data,
using the same code path as the real report.

![Bar chart showing the share of students meeting each learning outcome, four bars against a 70% target line, generated from synthetic demonstration data](img/plo_outcomes_demo.png)

## Reproducing this

```r
# Requires: tidyverse, readxl, writexl
Rscript data-raw/make_synthetic.R   # optional - output is already committed
```

Copy `.Renviron.example` to `.Renviron` (already points at the committed
synthetic data), then:

```r
source("R/report-internal-direct-2019.R")
Rscript R/plot_outcomes.R
```

## Repository layout

```
R/                  Pipeline scripts (read -> munge -> report -> plot)
data/               Real data path config (gitignored) + schema README
data/synthetic/     Committed synthetic stand-in data
data-raw/           Synthetic data generator
docs/               This case study and its figure
out/                Report outputs (gitignored, regenerated by the pipeline)
archive/            Other years' exploratory notebooks and one-off scripts,
                    kept for reference but not part of the current pipeline
```
