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
rootpath <- Sys.getenv("ACBSP_DATA_PATH")
path19 <- paste0(datapath, "\\AY2019 Backup\\Internal Direct Assessment\\")

# Import the students' learning outcome data
df <- read_xlsx(paste0(path, "Rubrics.xlsx")) %>%
  mutate(across(c(RubricId:Name, LevelAchieved), factor),
         IsScoreOverridden = (IsScoreOverridden == "True"))

# Import the assessment standard data (from MS Forms data)
# Contains both rubric and non-rubric information
survey <- read_excel(paste0(path, "Assessment Survey Responses.xlsx"), "Edited")
qs <- names(survey)
nms <- c("ID" = "ID",
         "Drop" = "Drop",
         "Start ti" = "Start",
         "Completi" = "Complete", 
         "Email" = "Email",
         "Name" = "Instructor",
         "In which" = "Semester",
         "Course A" = "Course.Section.Original",
         "Course" = "Course",
         "Section" = "Section",
         "What is " = "Assessment.Original",
         "Assessme" = "Assessment",
         "Follow u" = "Follow up",
         "I graded" = "Rubric",
         "Copy and" = "URL",
         "Analysis" = "Analysis.Rubric",
         "Action f" = "Action.Rubric",
         "What is " = "PLO.Original",
         "PLO" = "PLO",
         "What is " = "n.original",
         "n" = "n",
         "If this " = "np.original",
         "np" = "np",
         "Analysis" = "Analysis.Non.Rubric",
         "Action f" = "Action.Non.Rubric")
names(survey) <- nms

# Separate out the non-rubric data
# Non-rubric data are not relevant for D2L output data
non <- survey %>%
  filter(Rubric == "No", !Drop) %>%  select(-c(URL:Action.Rubric))
survey <- survey %>%
  filter(Rubric == "Yes", !Drop) %>%  select(ID:PLO)

# Extract rubric IDs (rubricid)
x <- str_extract_all(survey$URL, "rubricId=[0-9]{6}", simplify=TRUE)
survey$RubricId <- factor(str_extract_all(x, "[0-9]{6}", simplify=TRUE))
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

