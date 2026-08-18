# ==============================================================================
# Script Name: test-int-munge.R
# Purpose: Test the data initialization with small tables.
# Author: Kentaro Murayama (km7813a@gmail.com)
# Date Created: 2026-08-17
# Notes: Each uses a very small table to exercise one behavior.
# ==============================================================================

test_that("valid workbooks are read and joined", {
  data_root <- tempfile("read-fixture-")
  write_read_fixture(data_root)

  expect_message(
    result <- source_read_fixture(data_root),
    "0 of 1 rows"
  )

  expect_equal(nrow(result$mdf), 1L)
  expect_equal(as.character(result$mdf$RubricId), "100001")
  expect_equal(result$mdf$Instructor, "Test Instructor")
  expect_false(result$mdf$IsScoreOverridden)
  expect_equal(nrow(result$non), 0L)
})

test_that("rubric input schema is enforced", {
  data_root <- tempfile("missing-rubric-column-")
  write_read_fixture(data_root, omit_rubric_column = "LevelAchieved")

  expect_error(
    source_read_fixture(data_root),
    "missing required column\\(s\\): LevelAchieved"
  )
})

test_that("survey input schema is enforced", {
  data_root <- tempfile("missing-survey-column-")
  write_read_fixture(data_root, omit_survey_column = TRUE)

  expect_error(
    source_read_fixture(data_root),
    "Survey column count changed"
  )
})

test_that("rubric URL must contain an identifier", {
  data_root <- tempfile("bad-rubric-url-")
  write_read_fixture(data_root, url = "https://example.edu/rubrics/no-id")

  expect_error(
    source_read_fixture(data_root),
    "No rubricId found in URL for survey ID\\(s\\): 1"
  )
})

test_that("duplicate retained rubric mappings are rejected", {
  data_root <- tempfile("duplicate-rubric-")
  write_read_fixture(data_root, duplicate_rubric = TRUE)

  expect_error(
    source_read_fixture(data_root),
    "Multiple retained survey responses found for rubricId\\(s\\): 100001"
  )
})
