# Program Assessment Reporting

Turns messy, real-world student assessment records — inconsistent rubric
wording, mixed scoring scales, manual backfills — into a clean, comparable
outcome table a college accreditation committee can act on. The
measures themselves (which rubric criteria count toward which learning
outcome) weren't handed down fixed; they were developed and revised as
the data was explored.

## What's here

- `R/int_read.R` / `R/int_munge.R` — read and standardize raw rubric
  exports and instructor survey responses
- `R/report-internal-direct-2019.R` — aggregate the cleaned data to an
  outcome rate per learning goal
- `data-raw/make_synthetic.R` — generates safe stand-in data so the
  pipeline runs without any real student records
- `data/README.md` — documents the source schema and every data-quality
  quirk the cleaning code corrects for

![Bar chart showing the share of students meeting each learning outcome, four bars against a 70% target line, generated from synthetic demonstration data](docs/img/plo_outcomes_demo.png)

## How to run

```r
# Requires: tidyverse, readxl, writexl
Rscript data-raw/make_synthetic.R
```

Copy `.Renviron.example` to `.Renviron` (already points at the committed
synthetic data), then:

```r
source("R/report-internal-direct-2019.R")
Rscript R/plot_outcomes.R
```

To run against real data instead, point `ACBSP_DATA_PATH` at the real
data root (see `.Renviron.example`).

## What this demonstrates

Turning ambiguous raw data into a coherent measurement framework — not
just cleaning it, but deciding what it should mean — plus building a
reproducible R pipeline and working within student-privacy constraints
(real data never enters this repo; see `data/README.md`). For the fuller
story, including how the outcome categories emerged through exploratory
analysis: **[docs/CASE_STUDY.md](docs/CASE_STUDY.md)**.
