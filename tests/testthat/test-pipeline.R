test_that("synthetic pipeline produces stable, valid outputs", {
  sandbox <- make_pipeline_sandbox()
  withr::local_dir(sandbox)

  generator_env <- new.env(parent = globalenv())
  suppressWarnings(
    sys.source(
      project_path("data-raw", "make_synthetic.R"),
      envir = generator_env
    )
  )
  input_dir <- file.path(
    sandbox, "data", "synthetic", "AY2019", "Internal Direct Assessment"
  )
  withr::local_envvar(
    ACBSP_DATA_PATH = input_dir
  )

  pipeline_env <- new.env(parent = globalenv())
  expect_message(
    sys.source("R/report-internal-direct-2019.R", envir = pipeline_env),
    "Rubric-survey merge: 2 of 171 rows"
  )
  expect_true(file.exists("outputs/prg_internal.csv"))
  expect_true(file.exists("outputs/core_internal.csv"))

  program <- readr::read_csv(
    "outputs/prg_internal.csv", show_col_types = FALSE
  ) %>% arrange(plo)
  expected_program <- tribble(
    ~plo,    ~Met,                  ~n,
    "ACC 3", 0.9,                  10,
    "ECO 3", 0.5833333333333334,   12,
    "ECO 4", 0.5,                  12,
    "ECO 5", 0.5833333333333334,   12
  )
  expect_equal(as_tibble(program), expected_program, tolerance = 1e-10)
  expect_true(all(between(program$Met, 0, 1)))
  expect_true(all(program$n > 0))
  expect_identical(anyDuplicated(program$plo), 0L)

  core <- readr::read_csv(
    "outputs/core_internal.csv", show_col_types = FALSE
  ) %>% arrange(PLO)
  expected_core <- tribble(
    ~PLO, ~Met_Accounting, ~Met_ISBC, ~n_Accounting, ~n_ISBC,
    2,    0.4,             0.8,       5,             5,
    7,    0.6,             0.4,       5,             5,
    10,   0.5,             0.6,       5,             5
  )
  expect_equal(as_tibble(core), expected_core, tolerance = 1e-10)
  expect_true(all(between(unlist(core[c("Met_Accounting", "Met_ISBC")]), 0, 1)))

  expect_message(
    sys.source("R/plot_outcomes.R", envir = pipeline_env),
    "Wrote docs/img/plo_outcomes_demo.png"
  )
  expect_true(file.exists("docs/img/plo_outcomes_demo.png"))
  expect_gt(file.info("docs/img/plo_outcomes_demo.png")$size, 0)
})

test_that("empty mapping tables do not cause invalid row indexing", {
  sandbox <- make_pipeline_sandbox()
  withr::local_dir(sandbox)

  suppressWarnings(
    sys.source(
      project_path("data-raw", "make_synthetic.R"),
      envir = new.env(parent = globalenv())
    )
  )
  input_dir <- file.path(
    sandbox, "data", "synthetic", "AY2019", "Internal Direct Assessment"
  )
  workbook_path <- file.path(input_dir, "Assessment Data Main.xlsx")
  sheet_names <- c("prg", "core", "mba", "map_prg", "map_core", "map_mba")
  workbook <- setNames(
    lapply(sheet_names, function(sheet) {
      readxl::read_excel(workbook_path, sheet = sheet)
    }),
    sheet_names
  )
  workbook$map_prg <- workbook$map_prg[0, ]
  suppressWarnings(writexl::write_xlsx(workbook, workbook_path))

  withr::local_envvar(
    ACBSP_DATA_PATH = input_dir
  )
  expect_no_error(
    suppressMessages(
      sys.source(
        "R/report-internal-direct-2019.R",
        envir = new.env(parent = globalenv())
      )
    )
  )

  program <- readr::read_csv(
    "outputs/prg_internal.csv", show_col_types = FALSE
  )
  expect_equal(names(program), c("plo", "Met", "n"))
  expect_equal(nrow(program), 0L)
})
