library(tidyverse)
library(readxl)
## ---- import-d2l ----
rootpath <- "C:\\Users\\kentr\\California University of Pennsylvania"
datapath <- paste0(rootpath, "\\ACBSP data reporting - Documents\\Data\\")

path <- paste0(datapath, "Internal Direct Assessment\\")

fn <- "Rubrics.xlsx"
df <- read_xlsx(paste0(path, fn)) %>%
  mutate(across(c(RubricId:Name, LevelAchieved), factor),
         IsScoreOverridden = (IsScoreOverridden == "True"))

## ---- import-survey ----
fn <- "Assessment Survey Responses.xlsx"
survey <- read_excel(paste0(path, fn), "Edited")
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

# Non rubric data are not relevant for D2L output data
non <- survey %>%
  filter(Rubric == "No", !Drop) %>%  select(-c(URL:Action.Rubric))
survey <- survey %>%
  filter(Rubric == "Yes", !Drop) %>%  select(ID:PLO)

## ---- extract-rubricid ----
x <- str_extract_all(survey$URL, "rubricId=[0-9]{6}", simplify=TRUE)
survey$RubricId <- factor(str_extract_all(x, "[0-9]{6}", simplify=TRUE))

## ---- drop-duplicates ----
id.drop <- c(22, 66, 65, 61, 62, 114, 37, 64, 63)
df2 <- survey %>% filter(!ID %in% id.drop)


## ---- merge ----
mdf <- df %>%
  left_join(df2 %>%
              select(RubricId, Instructor, Semester,
                     Course, Section, Course.Section.Original,
                     Assessment, Assessment.Original,
                     Rubric, PLO.Original, PLO), by="RubricId")

# ## ---- import supplementary ----
# past <- read_excel("data/Assessment Data Main.xlsx", sheet = "Main")
# rowmap <- read_excel("data/Assessment Data Main.xlsx", sheet = "Mapping")
