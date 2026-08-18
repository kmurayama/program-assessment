# ==============================================================================
# Script Name: plot_outcomes.R
# Purpose: Turn out/prg_internal.csv (produced by report-internal-direct-2019.R)
#   into a single readable chart: share of students meeting the proficiency
#   target, per program learning outcome (PLO).
# Notes: Run after report-internal-direct-2019.R. Intended for the synthetic
#   demonstration data - the output is illustrative, not a real outcome report.
# ==============================================================================

library(tidyverse)

target <- 0.70

tbl <- read_csv("out/prg_internal.csv", show_col_types = FALSE) %>%
  mutate(plo = fct_reorder(plo, Met), met_target = Met >= target)

p <- ggplot(tbl, aes(Met, plo, fill = met_target)) +
  geom_col(width = 0.6) +
  geom_vline(xintercept = target, linetype = "dashed", color = "grey30") +
  scale_x_continuous(labels = scales::percent_format(), limits = c(0, 1)) +
  scale_fill_manual(values = c(`TRUE` = "#2c7a4b", `FALSE` = "#b3402f"),
                     guide = "none") +
  labs(title = "Share of Students Meeting Each Learning Outcome",
       subtitle = "Demonstration output from synthetic data - not real institutional results",
       x = "Share meeting target", y = NULL) +
  theme_minimal(base_size = 12) +
  theme(plot.subtitle = element_text(color = "grey40", size = 9))

dir.create("docs/img", recursive = TRUE, showWarnings = FALSE)
ggsave("docs/img/plo_outcomes_demo.png", p, width = 6.5, height = 4, dpi = 150)
message("Wrote docs/img/plo_outcomes_demo.png")
