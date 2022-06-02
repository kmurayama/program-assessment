# Check for survey entries
# Somehow the Form added "scores" as if quiz and there's no option to turn it off.
# Clean those columns. List entries and compare with the plan.

library(tidyverse)
library(readxl)

# Temporary folder
rootdir <- "C://Users/HP/OneDrive - California University of Pennsylvania/Data/AY2021 Backup/"
fns <- list.files(path = rootdir)
fns <- grep("Assessment Survey", fns, value=TRUE)
rawdfs <- lapply(paste0(rootdir, fns), read_excel)
# plandf <- read_excel(paste0(rootdir, "1. Assessment Plan at a Glance Copied.xlsx"))

# Clean data
cleandf <- function(mdf, semester){
  mdf <- mdf %>% select(!starts_with(c("Points", "Feedback")))
  mdf <- mdf %>% select(!c("Total points", "Quiz feedback"))
  # Check for expected column number
  ncol(mdf) == 16
  # If pass, then rename all
  mdfnames <- c("ID", "Time1", "Time2", "Email", "Name", "Program", "Number", "OnlySection", "Rubric", "URL",
                "AssessmentName", "ObjectiveName", "TotalN", "SatisfactoryN", "Analysis", "Action")
  colnames(mdf) <- mdfnames
  mdf <- mdf %>% 
    separate(Name, c("Name1", "Name2")) %>% 
    mutate(Course = paste0(Program, "-", Number),
           Section = paste0(Course, "-", OnlySection),
           NameSection = paste0(Name2, "-", Section))
  mdf$Semester <- semester
  mdf
}

surveys <- list()
fns
surveys[[1]] <- cleandf(rawdfs[[1]], "Fall 2021")
surveys[[2]] <- cleandf(rawdfs[[2]], "Summer 2021")
surveys[[3]] <- cleandf(rawdfs[[3]], "Spring 2022")

# Check entries
table(surveys[[1]]$NameSection)
table(surveys[[2]]$NameSection)
table(surveys[[3]]$NameSection)

# Check URL validity
survey <- bind_rows(surveys)
survey$rubricId <- str_extract_all(survey$URL, "rubricId=[0-9]{6}", simplify=TRUE)
survey$ou <- str_extract_all(survey$URL, "ou=[0-9]{7}", simplify=TRUE)

# survey$URL

# One error (May 20th retrieval)
survey[41, ]
survey[41, c("Name2", "Section", "Semester", "rubricId", "ou")]
survey[39:45, c("Name2", "Section", "Semester", "rubricId", "ou")]
# Another entry covered.

# Extract rubric ID... Old code, too much assumption about the order?
# ToDo: Fix and relfect on the code R/int_read.R
survey$RubricId <- factor(str_extract_all(survey$rubricId, "[0-9]{6}", simplify=TRUE))
survey[, c("RubricId", "rubricId")]

# Request
x <- as.numeric(levels(survey$RubricId))
# write.csv(x, file = "rubricid.csv", row.names = FALSE)

# Export the survey for the permanent storage
write.csv(survey, file = paste0(rootdir, "survey.csv"), row.names = FALSE)
