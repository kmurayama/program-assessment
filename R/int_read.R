# ==============================================================================
# Script Name: init_read.R
# Purpose: Read the data files stored outside the project 
# Author: Kentaro Murayama (km7813a@gmail.com)
# Date Created: 
# Notes: Data files are not included in the project for FERPA compliance. For a
# self-contained test run, use a synthetic data.
# ==============================================================================

# Load the libraries
library(tidyverse)
library(readxl)

# Set variables
datapath <- Sys.getenv("ACBSP_DATA_PATH")
stopifnot("Set ACBSP_DATA_PATH in .Renviron - see README" = nzchar(datapath))
path19 <- paste0(file.path(datapath, "AY2019 Backup", "Internal Direct Assessment"), "/")

# Import the students' learning outcome data
df <- read_xlsx(paste0(path19, "Rubrics.xlsx")) %>%
  mutate(across(c(RubricId:Name, LevelAchieved), factor),
         IsScoreOverridden = (IsScoreOverridden == "True"))

# Import the assessment standard data (from MS Forms data)
# Contains both rubric and non-rubric information
survey <- read_excel(paste0(path19, "Assessment Survey Responses.xlsx"), "Edited")
qs <- names(survey)

# Assign names to columns using the "codebook"
# Still assign names by position, but checks against expectations
codebook <- read_csv("R/survey_colnames.csv", col_types = "cc")
stopifnot(
  "Survey column count changed - update R/survey_colnames.csv" =
    nrow(codebook) == length(qs),
  "Survey question order/wording changed - update R/survey_colnames.csv" =
    all(str_starts(qs, fixed(codebook$prefix)))
)
names(survey) <- codebook$short_name

# Separate out the non-rubric data
# Non-rubric data are not relevant for D2L output data
non <- survey %>%
  filter(Rubric == "No", !Drop) %>%  select(-c(URL:Action.Rubric))
survey <- survey %>%
  filter(Rubric == "Yes", !Drop) %>%  select(ID:PLO)

# Extract rubric IDs (rubricid)
survey$RubricId <- factor(str_extract(survey$URL, "(?<=rubricId=)[0-9]{6}"))
missing_id <- survey$ID[is.na(survey$RubricId)]
if (length(missing_id) > 0) {
  stop("No rubricId found in URL for survey ID(s): ",
       paste(missing_id, collapse = ", "))
}
# Drop duplicates
id.drop <- c(22, 66, 65, 61, 62, 114, 37, 64, 63)
df2 <- survey %>% filter(!ID %in% id.drop)

# Merge the rubric information into the assessment data
mdf <- df %>%
  left_join(df2 %>%
              select(RubricId, Instructor, Semester,
                     Course, Section, Course.Section.Original,
                     Assessment, Assessment.Original,
                     Rubric, PLO.Original, PLO), by="RubricId")

# Report merge coverage
n_unmatched <- sum(is.na(mdf$Instructor))
message(sprintf("Rubric-survey merge: %d of %d rows (%.1f%%) have no matching survey response",
                 n_unmatched, nrow(mdf), 100 * n_unmatched / nrow(mdf)))

