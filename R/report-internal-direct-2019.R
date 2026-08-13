# Report the internal direct assessment outcomes for AY2019, using the rubric
# outcome data and identification information from the survey responses.
# Note that this is only for the *summative* assessment.

# Set variables
datapath <- Sys.getenv("ACBSP_DATA_PATH")
stopifnot("Set ACBSP_DATA_PATH in .Renviron - see README" = nzchar(datapath))
path19 <- paste0(file.path(datapath, "AY2019 Backup", "Internal Direct Assessment"), "/")

# Load the libraries
library(tidyverse)
library(readxl)
options(dplyr.summarise.inform=FALSE) 

# Import the new database and mapping
sns <- c("prg", "core", "mba")
mns <- paste0("map_", sns)
ldf <- sapply(sns, function(x) read_excel(paste0(path19, "Assessment Data Main.xlsx"), x), simplify = FALSE, USE.NAMES = TRUE)
lmp <- sapply(mns, function(x) read_excel(paste0(path19, "Assessment Data Main.xlsx"), x), simplify = FALSE, USE.NAMES = TRUE)

# Read the data and process it into a user-level data
source('R/int_read.R')
source('R/int_munge.R')

# 1. Summarize to section, semester level
# 2. Merge with non-rubric data
# 3. Summarize to course level
tbl1 <- mdf %>% filter(str_detect(Name, "Major|Minor", negate = TRUE)) %>%
  group_by(Course, Section, Semester, Assessment, Name, PLO) %>%
  summarise(Met.UND = mean(Met.UND.bin), Met.GRD = mean(Met.GRD.bin),
            n = n_distinct(UserId),
            Rubric = TRUE)
miss <- read_excel(paste0(path19, "D2L Missing Data Retrievals.xlsx"), "Scraped")
miss <- miss %>% mutate(Rubric = FALSE) %>% 
  select(-c(Unsatisfactory:Advanced)) %>% mutate(Met.UND = Met, Met.GRD = Met)
tbl2 <- bind_rows(tbl1, miss)
tbl3 <- tbl2 %>%
  bind_rows(non %>% transmute(Course, Section, Semester, Assessment,
                              Name = "No Rubric", PLO,
                              Met.UND = np/n, Met.GRD = Met.UND, n,
                              Rubric = FALSE))
tbl4 <- tbl3 %>% 
  group_by(Course, Assessment, Name, PLO, Rubric) %>%
  summarise(Met.UND = weighted.mean(Met.UND, n, na.rm = TRUE),
            Met.GRD = weighted.mean(Met.GRD, n, na.rm = TRUE),
            n = sum(n, na.rm = TRUE), n.sec = n_distinct(Section)
            ) %>% 
  ungroup()

# -4.a. Select program ---------------------------------------------------------
# Use the keys in the mapping.
map1 <- lmp$map_prg %>% filter(group1 == "Course")
tbl5 <- tbl4 %>% filter(PLO %in% map1$internal_rubric_tags)
# Filter out relevant information
lres <- list()
for(i in 1:nrow(map1)){
  x <- map1[i, ]
  lres[[i]] <- tbl5 %>%
    filter(PLO == x$internal_rubric_tags,
           str_detect(Name, x$internal_rubric_keys2019)) %>% 
    mutate(plo = x$plo)
}
# Summarized for PLOs and export
tbl_assess <- bind_rows(lres) %>%
  group_by(plo) %>%
  summarize(Met = mean(Met.UND), n = max(n))
write_csv(tbl_assess, "out/prg_internal.csv")


# 4.b. Select core -------------------------------------------------------------
map1c <- lmp$map_core %>% filter(group1 == "Course")
tbl5c <- tbl4 %>% filter(PLO %in% map1c$internal_rubric_tags)
# Filter out
lres <- list()
for(i in 1:nrow(map1c)){
  x <- map1c[i, ]
  lres[[i]] <- tbl5c %>%
    filter(PLO == x$internal_rubric_tags,
           str_detect(Name, x$internal_rubric_keys2019)) %>% 
    mutate(plo = x$plo)
}
# Summarized for PLOs
tbl_assess <- bind_rows(lres) %>%
  group_by(plo) %>%
  summarize(Met = mean(Met.UND), n = max(n))

# ------------------------------------------------------------------------------
# ...and also disaggregate by majors. Brute force.
attr <- mdf %>% filter(str_detect(Name, "Major|Minor")) %>% 
  select(RubricId, UserId, Course, Assessment, Name, LevelAchieved.Original)
attr.unq <- attr %>% distinct()

majors <- attr.unq %>% filter(Name == "Major")
majors.buscore <- majors %>% filter(Course == "BUS 499")

pttrn.major <- c("General Busines{1,3}" = "ISBC",
                 "Interdisciplinary Studies In Business And Commerce" = "ISBC",
                 "Integrated Global Business.*" = "ISBC")
majors.buscore <- majors.buscore %>%
  mutate(Major = str_to_title(LevelAchieved.Original),
         Major = str_replace_all(Major, pttrn.major))

sdf <- mdf %>% filter(Course == "BUS 499") %>%
  left_join(majors.buscore %>% select(RubricId, UserId, Major),
            by = c("RubricId", "UserId"))

res <- sdf %>% filter(str_detect(Name, "Major|Minor", negate = TRUE)) %>%
  group_by(Assessment, Name, PLO, Major) %>%
  summarise(Met.UND = mean(Met.UND.bin), Met.GRD = mean(Met.GRD.bin),
            n = n_distinct(UserId))
lres <- list()
lres[["PLO2"]] <- res %>% filter(str_detect(Name, "Plo2")) %>% group_by(Major) %>% summarise(Met = mean(Met.UND), n = min(n)) %>% mutate(PLO = 2)
lres[["PLO3"]] <- res %>% filter(str_detect(Name, "Plo3")) %>% group_by(Major) %>% summarise(Met = mean(Met.UND), n = min(n)) %>% mutate(PLO = 3)
lres[["PLO4"]] <- res %>% filter(str_detect(Name, "Plo4")) %>% group_by(Major) %>% summarise(Met = mean(Met.UND), n = min(n)) %>% mutate(PLO = 4)
lres[["PLO5"]] <- res %>% filter(str_detect(Name, "5[a|b|c|d]")) %>% group_by(Major) %>% summarise(Met = mean(Met.UND), n = min(n)) %>% mutate(PLO = 5)
lres[["PLO6"]] <- res %>% filter(str_detect(Name, "6[e|f|g]")) %>% group_by(Major) %>% summarise(Met = mean(Met.UND), n = min(n)) %>% mutate(PLO = 6)
lres[["PLO7"]] <- res %>% filter(str_detect(Name, "Plo7")) %>% group_by(Major) %>% summarise(Met = mean(Met.UND), n = min(n)) %>% mutate(PLO = 7)
lres[["PLO8"]] <- res %>% filter(str_detect(Name, "Plo8")) %>% group_by(Major) %>% summarise(Met = mean(Met.UND), n = min(n)) %>% mutate(PLO = 8)
lres[["PLO9"]] <- res %>% filter(str_detect(Name, "Plo9")) %>% group_by(Major) %>% summarise(Met = mean(Met.UND), n = min(n)) %>% mutate(PLO = 9)
lres[["PLO10"]] <- res %>% filter(str_detect(Name, ".*")) %>% group_by(Major) %>% summarise(Met = mean(Met.UND), n = min(n)) %>% mutate(PLO = 10)
out <- bind_rows(lres)

out_wide <- pivot_wider(out, id_cols = PLO, names_from = Major, values_from = c(Met, n))

write_csv(out_wide, "out/core_internal.csv")

