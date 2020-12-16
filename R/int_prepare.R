# Prepare for disaggregated data for Session 1
# Temporary solution. See note_disag_data_01.Rmd for details.

source('int_read.R')
source('int_munge.R')
attr <- mdf %>% filter(str_detect(Name, "Major|Minor")) %>% 
  select(RubricId, UserId, Course, Assessment, Name, LevelAchieved.Original)
attr.unq <- attr %>% distinct()
# dim(attr); dim(attr.unq)

majors <- attr.unq %>% filter(Name == "Major")
majors.buscore <- majors %>% filter(Course == "BUS 499")

pttrn.major <- c("General Busines{1,3}" = "ISBC",
                 "Interdisciplinary Studies In Business And Commerce" = "ISBC",
                 "Integrated Global Business.*" = "Integrated Global Business")
majors.buscore <- majors.buscore %>%
  mutate(Major = str_to_title(LevelAchieved.Original),
         Major = str_replace_all(Major, pttrn.major))
# table(majors.buscore$Major)
# head(majors.buscore)
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

dir.create("out")
saveRDS(out, "out/disag.Rds")

# Save comments
saveRDS(survey, "out/survey.Rds")
saveRDS(non, "out/non.Rds")


