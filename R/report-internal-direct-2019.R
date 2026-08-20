# Report the internal direct assessment outcomes for AY2019, using the rubric
# outcome data and identification information from the survey responses.
# Note that this is only for the *summative* assessment.

# Directory containing the four assessment input workbooks
input_dir <- Sys.getenv("ACBSP_DATA_PATH")
stopifnot("Set ACBSP_DATA_PATH in .Renviron - see README" = nzchar(input_dir))

# Load the libraries
library(tidyverse)
library(readxl)
options(dplyr.summarise.inform=FALSE) 

# Import the new database and mapping
sns <- c("prg", "core", "mba")
mns <- paste0("map_", sns)
ldf <- sapply(sns, function(x) read_excel(file.path(input_dir, "Assessment Data Main.xlsx"), x), simplify = FALSE, USE.NAMES = TRUE)
lmp <- sapply(mns, function(x) read_excel(file.path(input_dir, "Assessment Data Main.xlsx"), x), simplify = FALSE, USE.NAMES = TRUE)

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
miss <- read_excel(
  file.path(input_dir, "D2L Missing Data Retrievals.xlsx"), "Scraped"
)
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
for(i in seq_len(nrow(map1))){
  x <- map1[i, ]
  lres[[i]] <- tbl5 %>%
    filter(PLO == x$internal_rubric_tags,
           str_detect(Name, x$internal_rubric_keys2019)) %>% 
    mutate(plo = x$plo)
}
# Summarize for PLOs and export. An empty mapping, or a mapping with no
# matching rubric criteria, should produce an empty result instead of an
# indexing error or a max(n) = -Inf warning.
mapped <- bind_rows(lres)
if (nrow(mapped) == 0) {
  tbl_assess <- tibble(plo = character(), Met = double(), n = integer())
} else {
  tbl_assess <- mapped %>%
    group_by(plo) %>%
    summarize(Met = mean(Met.UND), n = max(n))
}
dir.create("outputs", recursive = TRUE, showWarnings = FALSE)
write_csv(tbl_assess, "outputs/prg_internal.csv")


# 4.b. Select core -------------------------------------------------------------
map1c <- lmp$map_core %>% filter(group1 == "Course")
tbl5c <- tbl4 %>% filter(PLO %in% map1c$internal_rubric_tags)
# Filter out
lres <- list()
for(i in seq_len(nrow(map1c))){
  x <- map1c[i, ]
  lres[[i]] <- tbl5c %>%
    filter(PLO == x$internal_rubric_tags,
           str_detect(Name, x$internal_rubric_keys2019)) %>% 
    mutate(plo = x$plo)
}
# Summarize for PLOs, including the valid empty-result case.
mapped <- bind_rows(lres)
if (nrow(mapped) == 0) {
  tbl_assess <- tibble(plo = character(), Met = double(), n = integer())
} else {
  tbl_assess <- mapped %>%
    group_by(plo) %>%
    summarize(Met = mean(Met.UND), n = max(n))
}

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
plo_patterns <- tribble(
  ~PLO.out, ~criterion_pattern,
   2L,      "Plo2",
   3L,      "Plo3",
   4L,      "Plo4",
   5L,      "5[abcd]",
   6L,      "6[efg]",
   7L,      "Plo7",
   8L,      "Plo8",
   9L,      "Plo9",
  10L,      ".*"       # Overall composite: include every criterion
)

out <- crossing(res, plo_patterns) %>%
  filter(str_detect(Name, criterion_pattern)) %>%
  group_by(PLO.out, Major) %>%
  summarise(
    Met = mean(Met.UND),
    n = min(n),
    .groups = "drop"
  ) %>%
  rename(PLO = PLO.out)

out_wide <- pivot_wider(out, id_cols = PLO, names_from = Major, values_from = c(Met, n))

write_csv(out_wide, "outputs/core_internal.csv")

