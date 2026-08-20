# Exploratory Analysis Archive

This directory preserves the exploratory work that led to the reporting
pipeline in [`R/`](../R/). The notebooks are useful because they show that the
final learning-outcome measures were not fixed in advance. They were developed
by repeatedly inspecting the data, testing interpretations, discussing results
with faculty and committee members, and revising the mappings and reports.

The archive is therefore a record of analytical decisions, not a second
production pipeline. For the reproducible demonstration, synthetic data, and
current tests, start with the [project README](../README.md).

## Development path

| Stage | Main question | What changed | Representative notebooks |
| --- | --- | --- | --- |
| Initial exploration | What patterns and data limitations are visible? | Compared trends, internal and external measures, and results against targets; noted missingness, changing standards, and possible instructor effects. | [`note_inspecting_assessment_01.Rmd`](note_inspecting_assessment_01.Rmd) |
| Discussion-ready analysis | How can the findings support department conversations? | Turned early plots into mapping-driven, program-level views for faculty meetings and strategic planning. | [`note_inspecting_assessment_02.Rmd`](note_inspecting_assessment_02.Rmd), [`note_prepare_acbsp_tables.Rmd`](note_prepare_acbsp_tables.Rmd) |
| Collaborative revision | Which definitions, displays, and comparisons are actually useful? | Recorded specification corrections, requests for supporting data, presentation changes, new disaggregations, and follow-up questions from the first review session. | [`note_session1_feedback_01.Rmd`](note_session1_feedback_01.Rmd), [`session1/`](session1/) |
| Operationalization | Which parts of the exploratory process are stable enough to automate? | Simplified the transformations, moved definitions into mapping tables, and established section-, course-, and outcome-level aggregation. | [`note_annual-reports-02.Rmd`](note_annual-reports-02.Rmd), [`note_annual-reports-03.Rmd`](note_annual-reports-03.Rmd) |
| New-cycle stress test | Does the framework survive another year of differently structured data? | Checked raw vocabularies and identifiers, reviewed exceptions course by course, investigated duplicate links, and generalized scoring rules. | [`ay2020/note-prelim-01-test-data.Rmd`](ay2020/note-prelim-01-test-data.Rmd), [`ay2020/note-prelim-02-process.Rmd`](ay2020/note-prelim-02-process.Rmd) |
| Standardization | How should recurring inconsistencies be handled reproducibly? | Separated systematic corrections from manual review, defined canonical columns and scales, and treated lookup tables as the reference layer. | [`ay2021/note01-standardize-data.Rmd`](ay2021/note01-standardize-data.Rmd), [`ay2021/note02-read-ay21-data.Rmd`](ay2021/note02-read-ay21-data.Rmd) |

## How the data was inspected

The exploration followed a recurring sequence:

1. **Inventory the raw structure.** Inspect column names, sample rows, distinct
   values, factor levels, and frequency tables before changing anything.
2. **Restore context.** Join rubric records to survey responses and lookup
   tables so each score can be interpreted by program, course, assignment,
   criterion, and learning outcome.
3. **Slice progressively.** Move from program-level summaries to individual
   courses, assignments, rubric rows, sections, and student groups when an
   aggregate result looks unusual.
4. **Check the data contract.** Look for missing mappings, duplicate or reused
   identifiers, inconsistent labels, incomplete sections, changed rubrics, and
   incompatible achievement scales.
5. **Compare plausible interpretations.** Examine time trends, internal versus
   external measures, actual results versus targets, and alternative levels of
   aggregation. Sample sizes and contextual caveats remain visible during this
   step.
6. **Review with subject-matter experts.** Present preliminary views to faculty,
   collect corrections and instructional context, and revise priorities,
   mappings, and displays.
7. **Promote stable logic.** Move transformations that continue to work across
   programs and reporting cycles into reusable scripts; keep definitions that
   may change in lookup tables rather than burying them in code.

This process helped distinguish at least three different causes of an unusual
result: a source-data problem, a change in the assessment instrument or its
implementation, or a potentially meaningful difference in student outcomes.

## Suggested reading order

Readers do not need to open every notebook. The following sequence provides a
compact view of the evolution:

1. [`note_inspecting_assessment_01.Rmd`](note_inspecting_assessment_01.Rmd) —
   open-ended exploration and the first analytical questions.
2. [`note_inspecting_assessment_02.Rmd`](note_inspecting_assessment_02.Rmd) —
   reusable views prepared for faculty discussion.
3. [`note_session1_feedback_01.Rmd`](note_session1_feedback_01.Rmd) — the
   feedback loop and resulting revisions.
4. [`note_annual-reports-02.Rmd`](note_annual-reports-02.Rmd) — consolidation of
   the emerging measurement and reporting scheme.
5. [`ay2020/note-prelim-01-test-data.Rmd`](ay2020/note-prelim-01-test-data.Rmd)
   and [`ay2020/note-prelim-02-process.Rmd`](ay2020/note-prelim-02-process.Rmd)
   — validation against a new annual dataset.
6. [`ay2021/note01-standardize-data.Rmd`](ay2021/note01-standardize-data.Rmd) —
   the transition to a more explicit, cross-year standardization framework.

The conference materials summarize the same process for an external audience:

- [`memo_conference_acbsp_nov2020.md`](memo_conference_acbsp_nov2020.md)
- [`slides_acbsp_regional_01.Rmd`](slides_acbsp_regional_01.Rmd)
- [`slides_acbsp_regional_03.Rmd`](slides_acbsp_regional_03.Rmd)

## From notebooks to the current pipeline

The exploratory logic was progressively extracted into the scripts under
[`R/`](../R/):

- [`int_read.R`](../R/int_read.R) reads source files and reconciles their
  structures.
- [`int_munge.R`](../R/int_munge.R) standardizes and reshapes the assessment
  records.
- [`report-internal-direct-2019.R`](../R/report-internal-direct-2019.R)
  aggregates the cleaned records and maps rubric evidence to learning outcomes.
- [`plot_outcomes.R`](../R/plot_outcomes.R) creates the final outcome display.

In particular, the section aggregation, mapping, and disaggregation developed
in [`note_annual-reports-02.Rmd`](note_annual-reports-02.Rmd) can be followed
into [`report-internal-direct-2019.R`](../R/report-internal-direct-2019.R). This
is the clearest bridge between the exploratory record and the end product.

## Reproducibility and privacy notes

- The notebooks were working documents. They include experiments, abandoned
  approaches, unresolved questions, and repeated code by design.
- Some notebooks depend on confidential source files, historical file paths,
  or package behavior that is no longer available. They are not expected to
  knit independently from a fresh clone.
- Real student records are not included in this repository. Use the synthetic
  workflow described in the [project README](../README.md) to run and test the
  current pipeline.
- Some notes refer to conversations with individual collaborators. These
  references document the validation process; they should not be interpreted
  as student-level data or formal committee minutes.
- One consolidation notebook refers to an earlier notebook from a separate
  `internal-direct` project. That file is not present here, so the archive does
  not capture the absolute origin of every helper function.

For the portfolio narrative and project outcomes, see the
[case study](../docs/CASE_STUDY.md).
