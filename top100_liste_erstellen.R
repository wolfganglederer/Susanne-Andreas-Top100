library(tidyverse)
library(clipr)

top100_fin <- read_csv("./data/top100_2026-09-28.csv")


top100_sort <-
  top100_fin |>
  arrange(desc(total_points), desc(n_votes)) |>
  mutate(
    top100_titel = min_rank(tibble(desc(total_points), desc(n_votes), title)),
    top100_ties = min_rank(tibble(desc(total_points), desc(n_votes)))
  ) |>
  arrange(top100_titel)


write_csv(top100_sort, "./data/top100_fin_sort.csv")


## Top 300 für Hitster erstellen

top100_fin_oct <- read_csv("./data/v_top_100_overall_rows-2026-10-04.csv")


top100_sort_oct <-
  top100_fin_oct |>
  arrange(desc(total_points), desc(n_votes)) |>
  mutate(
    top100_titel = min_rank(tibble(desc(total_points), desc(n_votes), title)),
    top100_ties = min_rank(tibble(desc(total_points), desc(n_votes)))
  ) |>
  arrange(top100_titel) |>
  slice_head(n = 300)

write_csv(top100_sort_oct, "./data/top300_hitster.csv")
