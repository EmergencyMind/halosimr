test_that("generation is reproducible and well-formed", {
  e1 <- generate_events(365, rate = 0.1, seed = 11)
  e2 <- generate_events(365, rate = 0.1, seed = 11)
  expect_identical(e1, e2)
  expect_identical(names(e1), c("day_idx", "date", "shift_type"))
  expect_true(all(e1$day_idx >= 0 & e1$day_idx < 365))
  expect_true(all(e1$shift_type %in% c("day", "night")))
})

test_that("event volume tracks rate x n_days and splits ~50/50", {
  e <- generate_events(365, rate = 0.1, seed = 11)  # ~36.5 events
  expect_lt(abs(nrow(e) - 36.5), 20)
  expect_lt(abs(mean(e$shift_type == "day") - 0.5), 0.2)
})

test_that("split rates weight the shifts", {
  es <- suppressWarnings(
    generate_events(365, rate = 0, seed = 5, day_rate = 0.3, night_rate = 0.02))
  expect_gt(sum(es$shift_type == "day"), sum(es$shift_type == "night"))
})

test_that("load_events drops out-of-window events", {
  edf <- data.frame(date = c("2024-01-01", "2023-12-31", "2024-01-10"),
                    shift_type = c("day", "night", "day"), stringsAsFactors = FALSE)
  le <- suppressWarnings(load_events(edf, n_days = 5, start_date = "2024-01-01"))
  expect_equal(nrow(le), 1L)
  expect_equal(le$day_idx, 0L)
})

test_that("load_events rejects missing columns and bad codes", {
  expect_error(load_events(data.frame(shift_type = "day"), n_days = 5),
               "Missing required column")
  expect_error(load_events(data.frame(date = "2024-01-01", shift_type = "swing"),
                           n_days = 5), "Invalid shift_type")
})
