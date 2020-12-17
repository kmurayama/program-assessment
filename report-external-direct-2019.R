# Report the internal direct assessment outcomes for AY2019, using the rubric
# outcome data and identification information from the survey responses.
# Note that this is only for the *summative* assessment.

# Set up
library(tidyverse)
options(dplyr.summarise.inform=FALSE) 
library(readxl)
library(lubridate)
datapath <- "C:\\Users\\kentr\\California University of Pennsylvania\\ACBSP data reporting - Documents\\Data\\"

# Import the new database and mapping
sns <- c("prg", "core", "mba")
mns <- paste0("map_", sns)
ldf <- sapply(sns, function(x) read_excel(paste0(datapath, "Assessment Data Main.xlsx"), x), simplify = FALSE, USE.NAMES = TRUE)
lmp <- sapply(mns, function(x) read_excel(paste0(datapath, "Assessment Data Main.xlsx"), x), simplify = FALSE, USE.NAMES = TRUE)

# Import score data
fn <- "External Direct Comparison//IndividualResults_UND.xlsx"
tmp1 <- read_excel(paste0(datapath, fn), sheet = 2, skip = 5)
fn <- "External Direct Comparison//IndividualResults_MBA.xlsx"
tmp2 <- read_excel(paste0(datapath, fn), sheet = 2, skip = 5)
tmp3 <- bind_rows(tmp1, tmp2)
names(tmp3)[1] <- "ID"
mdf <- tmp3 %>% select(-(Learner:`Student ID`)) # Remove private information
rm(list = ls(pattern = "tmp?"))

# Import benchmark scores
fn <- "External Direct Comparison//External Direct Comparison.xlsx"
ref <- read_excel(paste0(datapath, fn), "Both")
names(ref) <- c("Course", "Timeline", "Score", "ACBSP_US", "ACBSP_R2", "US",
                "MSCHE", "Public", "Degree")

# Create variables, reshape data set, and merge benchmark score data. ----------
mdf <- mdf %>%
  mutate(
    Time = ymd_hms(Completed),
    AY = case_when(
      Time %within% interval(ymd("2016-06-01"), ymd("2017-05-31")) ~ "2016",
      Time %within% interval(ymd("2017-06-01"), ymd("2018-05-31")) ~ "2017",
      Time %within% interval(ymd("2018-06-01"), ymd("2019-05-31")) ~ "2018",
      Time %within% interval(ymd("2019-06-01"), ymd("2020-05-31")) ~ "2019",
      TRUE ~ "Other"),
    Major = `Identify Your Major or Concentration`,
    Minor = `Identify Your Minor or Certificate`,
    Specialization = `MBA Specialization`,
    Degree = Program)

# Filter entries with less than 30 min spent
mdf.original <- mdf
mdf <- mdf %>% filter(`Duration (min)` > 30)

# Reshape the data
lmdf <- mdf %>% select(-c(Timeline, Faculty, Course)) %>% 
  pivot_longer(cols = c(Accounting:`Final Score`),
               names_to = "Course", values_to = "Score")
# Merge the benchmark scores and compute differences
# Need this at this stage in order to summarize prevelence of achievements
lmdf <- lmdf %>%
  left_join(ref %>% select(Course, ACBSP_US, ACBSP_R2, US, Degree),
            by = c("Degree", "Course")) %>% 
  mutate(Diff = Score - US)

# Name has changed 2019 for *General Business* to *ISBC* (along with the program
# change). Count them together.
genbus <- "(General Business)|(Integrated Global Business)|(Interdisciplinary Studies in Business and Commerce)"
lmdf <- lmdf %>%
  mutate(Major = str_replace(Major, genbus, "ISBC"),
         Degree = str_replace(Degree, "BS", "UND"))

# Aggregate ----
# Aggregate: All students
tbl1 <- lmdf %>% group_by(Degree, AY, Course) %>% 
  summarise(mean = mean(Score, na.rm = TRUE)/100,
            mean_diff = mean(Diff, na.rm = TRUE)/100,
            met = mean(Diff >0, na.rm = TRUE),
            n = n_distinct(ID)) %>%
  mutate(Major = "All", Specialization = "All")
# Disaggregate: By major
tbl2 <- lmdf %>% filter(Degree == "UND") %>% 
  group_by(AY, Major, Course) %>% 
  summarise(mean = mean(Score, na.rm = TRUE)/100,
            mean_diff = mean(Diff, na.rm = TRUE)/100,
            met = mean(Diff >0, na.rm = TRUE),
            n = n_distinct(ID)) %>% 
  mutate(Degree = "UND")
# Disaggregate: By specialization
tbl3 <- lmdf %>% filter(Degree == "MBA") %>% 
  group_by(AY, Specialization, Course) %>% 
  summarise(mean = mean(Score, na.rm = TRUE)/100,
            mean_diff = mean(Diff, na.rm = TRUE)/100,
            met = mean(Diff >0, na.rm = TRUE),
            n = n_distinct(ID)) %>% 
  mutate(Degree = "MBA")
tbl_all <- bind_rows(tbl1, tbl2, tbl3)
# tbl_und <- bind_rows(tbl1 %>% select(-Specialization), tbl2)
# tbl_mba <- bind_rows(tbl2 %>% select(-Major), tbl3)

# Re-introduce benchmark. Use only US.
ref <- ref %>% mutate(Degree = str_replace(Degree, "BS", "UND"))
tbl_all <- tbl_all %>%
  left_join(ref %>% select(Degree, Course, US),
            by = c("Degree", "Course")) %>% 
  mutate(US = US/100)

# Select program ----
map2 <- lmp$map_prg %>% filter(source == "External")

# Extract relevant rows from the outcome summary
# while adding the identification information
lres <- list()
for(i in 1:nrow(map2)){
  x <- map2[i, ]
  z1 <- tbl_all %>%
    filter(Degree == "UND", Major == x$group2, Course == x$tool) %>%
    select(AY, Degree, Major, Course, n, mean, met, US) %>% 
    mutate(Program = x$program, PLO = x$plo)
  z2 <- tbl_all %>%
    filter(Degree == "UND", Major == x$external_control_group, Course == x$tool) %>%
    select(AY, Degree, Control = Major, n_ctrl = n, mean_ctrl = mean, met_contrl = met)
  lres[[i]] <- left_join(z1, z2, by = c("AY", "Degree"))
}
out_program <- bind_rows(lres) %>% arrange(Program, PLO, Major, AY)

write_csv(out_program, "out/prg_external.csv")


# Select core ----
map3 <- lmp$map_core %>% filter(group1 == "CPC")

# Extract relevant rows from the outcome summary
# while adding the identification information
lres <- list()
for(i in 1:nrow(map3)){
  x <- map3[i, ]
  dfx <- tbl_all %>% filter(Degree == "UND", Major == x$group2, Course == x$tool)
  lres[[i]] <- dfx %>% select(AY, Degree, Major, Course, n, mean, met, US) %>% 
    mutate(Program = x$program, PLO = x$plo, Source = x$source)
}
out_core <- bind_rows(lres) %>% arrange(Program, PLO, Major, AY)

# Filter out
lres <- list()
lmaj <- levels(factor(tbl_all$Major))
k <- 0
for(i in 1:nrow(map3)){
  x <- map3[i, ]
  for(j in 1:length(lmaj)){
    y <- lmaj[j]
    k <- k + 1
    # print(c(i, j, k))
    dfx <- tbl_all %>% filter(Degree == "UND", Major == y, Course == x$tool)
    lres[[k]] <- dfx %>% select(AY, Degree, Major, Course, n, mean, met, US) %>%
      mutate(Program = x$program, PLO = x$plo, Source = x$source)
  }
}
out_core_dis <- bind_rows(lres)


core_dis <- pivot_wider(out_core_dis, id_cols = c(AY, PLO, Source), names_from = Major, values_from = c(mean, met, n))
out_core_full <- out_core %>% left_join(core_dis, by = c("AY", "PLO", "Source")) %>% arrange(Source, PLO, AY) %>% relocate(Source, PLO, AY)

write_csv(out_core_full, "out/core_external.csv")


# Select MBA ----
map4 <- lmp$map_mba %>% filter(group1 == "CPC")
# Extract relevant rows from the outcome summary
# while adding the identification information
lres <- list()
for(i in 1:nrow(map4)){
  x <- map4[i, ]
  dfx <- tbl_all %>% filter(Degree == "MBA", Major == x$group2, Course == x$tool)
  lres[[i]] <- dfx %>% select(AY, Degree, Major, Course, n, mean, met, US) %>% 
    mutate(Program = x$program, PLO = x$plo, Source = x$source)
}
out_core <- bind_rows(lres) %>% arrange(Program, PLO, Major, AY)

lres <- list()
lmaj <- levels(factor(tbl_all$Specialization))
k <- 0
for(i in 1:nrow(map4)){
  x <- map4[i, ]
  for(j in 1:length(lmaj)){
    y <- lmaj[j]
    k <- k + 1
    dfx <- tbl_all %>% filter(Degree == "MBA", Specialization == y, Course == x$tool)
    lres[[k]] <- dfx %>% select(AY, Degree, Specialization, Course, n, mean, met, US) %>%
      mutate(Program = x$program, PLO = x$plo, Source = x$source)
  }
}
out_core_dis <- bind_rows(lres)

core_dis <- pivot_wider(out_core_dis, id_cols = c(AY, PLO, Source), names_from = Specialization, values_from = c(mean, met, n))
out_core_full <- out_core %>% left_join(core_dis, by = c("AY", "PLO", "Source"))  %>% arrange(Source, PLO, AY) %>% relocate(Source, PLO, AY)
out_core_full

write_csv(out_core_full, "out/mba_external.csv")

# Still need improvements though.
# - MBA lacking 2016
# - Column names? (See the resulting sheets and find improvements)
