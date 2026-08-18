# ==============================================================================
# Script Name: test-int-munge.R
# Purpose: Test the data initialization with small tables.
# Author: Kentaro Murayama (km7813a@gmail.com)
# Date Created: 2026-08-17
# Notes: 
# ==============================================================================

test_that("achievement scales and proficiency flags are normalized", {
  input <- tibble(
    Name = rep("Criterion", 5),
    Course = rep("BUS 499", 5),
    Section = rep("BUS 499 001", 5),
    LevelAchieved = factor(c(
      "Level 0", "Level 2", "Level 4", "Good (85%)",
      "Unsatisactory (<60%)"
    ))
  )

  actual <- run_munge(input)

  expect_equal(
    as.character(actual$LevelAchieved),
    c("Unacceptable", "Fair", "Excellent", "Good", "Unacceptable")
  )
  expect_equal(actual$Met.UND.bin, c(FALSE, TRUE, TRUE, TRUE, FALSE))
  expect_equal(actual$Met.GRD.bin, c(FALSE, FALSE, TRUE, TRUE, FALSE))
})

test_that("course-specific criterion names are standardized", {
  input <- tibble(
    Name = c("Citations", "Structure", "Citations", "Structure"),
    Course = c("ECO 201", "ECO 201", "ECO 202", "ECO 202"),
    Section = paste("Section", 1:4),
    LevelAchieved = factor(rep("Proficient", 4))
  )

  actual <- run_munge(input)

  expect_equal(
    actual$Name,
    c(
      "Citations/References", "Structure/Clarity",
      "Writing: Citations", "Writing: Structure"
    )
  )
})

test_that("attribute names, online sections, and stray rows are handled", {
  input <- tibble(
    Name = c("Major/Concentration", "Minor/Certificate", "New Criterion"),
    Course = rep("BUS 499", 3),
    Section = c("BUS 499 GW1", "BUS 499 001", "BUS 499 001"),
    LevelAchieved = factor(c("Accounting", "None", NA))
  )

  actual <- run_munge(input)

  expect_equal(actual$Name, c("Major", "Minor"))
  expect_equal(actual$Online, c(TRUE, FALSE))
  expect_equal(actual$Met.UND, c("Missing", "Missing"))
  expect_equal(actual$Met.UND.bin, c(FALSE, FALSE))
})

test_that("unexpected achievement wording fails with useful detail", {
  input <- tibble(
    Name = "Critical Thinking",
    Course = "BUS 499",
    Section = "BUS 499 001",
    LevelAchieved = factor("Mastery")
  )

  expect_error(
    run_munge(input),
    "Critical Thinking: Mastery \\(1\\)"
  )
})
