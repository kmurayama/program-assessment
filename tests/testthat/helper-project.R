suppressPackageStartupMessages(library(tidyverse))

program_assessment_root <- normalizePath(
  testthat::test_path("..", ".."),
  winslash = "/",
  mustWork = TRUE
)

project_path <- function(...) {
  normalizePath(
    file.path(program_assessment_root, ...),
    winslash = "/",
    mustWork = FALSE
  )
}

run_munge <- function(input) {
  script_env <- new.env(parent = globalenv())
  script_env$mdf <- input
  sys.source(project_path("R", "int_munge.R"), envir = script_env)
  script_env$mdf
}

write_read_fixture <- function(input_dir, url = NULL, duplicate_rubric = FALSE,
                               omit_rubric_column = NULL,
                               omit_survey_column = FALSE) {
  dir.create(input_dir, recursive = TRUE, showWarnings = FALSE)

  rubrics <- tibble(
    RubricId = 100001,
    UserId = 1,
    Name = "Criterion",
    Score = 4,
    LevelAchieved = "Good",
    Feedback = "",
    IsScoreOverridden = "False"
  )
  if (!is.null(omit_rubric_column)) {
    rubrics[[omit_rubric_column]] <- NULL
  }
  writexl::write_xlsx(
    list(Rubrics = rubrics), file.path(input_dir, "Rubrics.xlsx")
  )

  codebook <- readr::read_csv(
    project_path("R", "survey_colnames.csv"),
    col_types = "cc",
    show_col_types = FALSE
  )
  if (is.null(url)) {
    url <- paste0(
      "https://example.edu/rubrics?rubricId=100001&isPopup=1"
    )
  }

  values <- list(
    ID = 1,
    Drop = FALSE,
    Start = "2019-01-01",
    Complete = "2019-01-01",
    Email = "instructor@example.edu",
    Instructor = "Test Instructor",
    Semester = "Fall 2019",
    Course.Section.Original = "ECO 201 - 001",
    Course = "ECO 201",
    Section = "ECO 201 001",
    Assessment.Original = "Test Assessment",
    Assessment = "Test Assessment",
    `Follow up` = "",
    Rubric = "Yes",
    URL = url,
    Analysis.Rubric = "",
    Action.Rubric = "",
    PLO.Original = "Economics PLO 1",
    PLO = "ECO 1",
    n.original = 1,
    n = 1,
    np.original = 1,
    np = 1,
    Analysis.Non.Rubric = "",
    Action.Non.Rubric = ""
  )
  survey <- tibble::as_tibble(values)
  stopifnot(identical(names(survey), codebook$short_name))
  names(survey) <- paste0(codebook$prefix, " fixture ", seq_len(nrow(codebook)))

  if (duplicate_rubric) {
    survey <- bind_rows(survey, survey)
    survey[[1]] <- c(1, 2)
  }
  if (omit_survey_column) {
    survey[[ncol(survey)]] <- NULL
  }
  writexl::write_xlsx(
    list(Edited = survey),
    file.path(input_dir, "Assessment Survey Responses.xlsx")
  )

  invisible(input_dir)
}

source_read_fixture <- function(input_dir) {
  script_env <- new.env(parent = globalenv())
  withr::local_envvar(ACBSP_DATA_PATH = input_dir)
  withr::local_dir(project_path())
  sys.source(project_path("R", "int_read.R"), envir = script_env)
  script_env
}

make_pipeline_sandbox <- function() {
  sandbox <- tempfile("program-assessment-test-")
  dir.create(sandbox, recursive = TRUE)
  file.copy(
    project_path("R"), sandbox,
    recursive = TRUE, copy.date = FALSE
  )
  sandbox
}
