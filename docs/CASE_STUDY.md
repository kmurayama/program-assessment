# Case Study: Program Assessment Reporting

> **Data note:** the original project ran on confidential student and
> instructor records that can't be shared publicly. Everything in this
> repository, including the figure below, runs on a small synthetic
> dataset built to reproduce the real data's structure and quirks —
> not its actual values. Where this case study describes the real
> project's outputs, it does so in general terms, without institution
> names or real outcome numbers.

## In brief

The main result was not only an automated accreditation report. It was a
measurement framework that became more defensible with each reporting cycle.
I used exploratory notebooks to inspect unfamiliar source data, test possible
definitions, and prepare views for faculty discussion. Feedback from those
discussions corrected specifications, added instructional context, and changed
both the mappings and the presentation. Once a rule continued to work across
programs and annual datasets, I moved it into the reusable R pipeline.

That progression—exploration → collaborative validation → standardization →
automation—is the central analytical contribution documented by this
repository.

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
scheme. The measurement definitions were developed collaboratively; I
independently implemented the analyst-side counterpart in this repository—code
that turns the resulting raw exports into the standardized outcome tables
accreditation requires.

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

## The measurement framework emerged through iteration

The mapping in step 3—which rubric criteria count toward which PLO—was
not decided once and frozen. It emerged from a documented cycle of data
inspection, provisional analysis, faculty review, and revision. The notebooks
in [`archive/`](../archive/) preserve that reasoning trail; the
[`archive/README.md`](../archive/README.md) provides a guided reading order.

| Stage | Question being answered | Evidence in the archive | Lasting change |
|---|---|---|---|
| Diagnostic exploration | What patterns are visible, and which apparent patterns might instead be missing data, changing standards, or implementation differences? | [`note_inspecting_assessment_01.Rmd`](../archive/note_inspecting_assessment_01.Rmd) | Established three complementary views: trends, internal-versus-external comparison, and actual-versus-target differences. |
| Discussion-ready analysis | How can the analysis support department decisions rather than just describe the dataset? | [`note_inspecting_assessment_02.Rmd`](../archive/note_inspecting_assessment_02.Rmd) and [`note_prepare_acbsp_tables.Rmd`](../archive/note_prepare_acbsp_tables.Rmd) | Replaced one-off plots with mapping-driven program reports that retained targets, sample sizes, and contextual notes. |
| Collaborative review | Which specifications are wrong, which comparisons are useful, and what context is missing? | [`note_session1_feedback_01.Rmd`](../archive/note_session1_feedback_01.Rmd) | Corrected mappings, reorganized the presentation, added requested disaggregations, and identified source records requiring follow-up. |
| Consolidation | Which exploratory rules are stable enough to become part of the reporting process? | [`note_annual-reports-02.Rmd`](../archive/note_annual-reports-02.Rmd) | Moved definitions into lookup tables and standardized aggregation from section to course to PLO. |
| Cross-year stress test | Does the scheme still work when a new annual export uses different labels, identifiers, and rubric structures? | [`ay2020/note-prelim-01-test-data.Rmd`](../archive/ay2020/note-prelim-01-test-data.Rmd) and [`ay2020/note-prelim-02-process.Rmd`](../archive/ay2020/note-prelim-02-process.Rmd) | Generalized achievement scales, investigated duplicate identifiers, and separated recurring transformations from cases needing human review. |
| Standardization | How should the next cycle preserve comparability without hiding real changes in instruments? | [`ay2021/note01-standardize-data.Rmd`](../archive/ay2021/note01-standardize-data.Rmd) | Defined canonical columns and reference tables while preserving year-specific mappings and exceptions. |

### How I inspected the data

The notebooks show a recurring analytical method rather than a sequence of
unrelated cleanup tasks:

1. **Inventory the raw vocabulary.** I inspected column names, sample rows,
   distinct values, factor levels, and frequency tables before recoding them.
2. **Restore assessment context.** I joined rubric rows to survey responses and
   lookup tables so a score could be traced to a program, course, assignment,
   criterion, and intended learning outcome.
3. **Slice progressively.** When an aggregate looked unusual, I moved down
   through course, assignment, rubric criterion, section, and student group to
   locate the source of the difference.
4. **Test the data contract.** I checked for missing mappings, duplicate or
   reused identifiers, inconsistent labels, changed rubrics, incomplete
   sections, and incompatible achievement scales.
5. **Compare interpretations.** I examined time trends, internal and external
   measures, results against targets, and different aggregation levels while
   retaining sample size and qualitative context.
6. **Validate with faculty.** Preliminary graphs and mockups were discussion
   tools. Faculty supplied corrections and instructional explanations, and the
   committee's priorities determined which comparisons and disaggregations
   became part of the report.

This method helped distinguish three fundamentally different explanations for
an unusual result: a source-data error, a change in an assessment instrument or
its implementation, or a potentially meaningful difference in student
learning. Automating before resolving that distinction would have made the
pipeline more consistent but not necessarily more valid.

### How exploration became production code

The transition is visible in the repository. The section aggregation,
mapping, and disaggregation developed in
[`note_annual-reports-02.Rmd`](../archive/note_annual-reports-02.Rmd) were
subsequently extracted into
[`R/report-internal-direct-2019.R`](../R/report-internal-direct-2019.R).
Similarly, recurring decisions about scale values, criterion names, attributes,
and missing records became explicit transformations and validation checks in
[`R/int_read.R`](../R/int_read.R) and [`R/int_munge.R`](../R/int_munge.R).

The data schema preserves separate mapping columns for consecutive years
(`internal_rubric_keys2019` and `internal_rubric_keys2020`) rather than
overwriting the earlier definition. This makes a substantive change to the
measurement scheme visible instead of creating a false appearance of perfect
comparability across cycles.

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

## What the public version cannot demonstrate

The synthetic dataset demonstrates the pipeline's behavior, validation rules,
and output structure, but it cannot reproduce the real program-level findings
or every historical edge case. The archived notebooks also depend in places on
confidential files, historical paths, and older package behavior, so they are
evidence of the analytical process rather than independently reproducible
reports. One consolidation notebook refers to an earlier notebook in a
separate project that is not included here; the archive therefore captures most,
but not every step, in the code's early history.

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
archive/            Exploratory notebooks and feedback records documenting
                    how the measurement framework developed
```
