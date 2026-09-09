.sfn <- function(s) generate_schedule(60, 120, "3/7 Day", seed = s)
.efn <- function(s) generate_events(120, rate = 0.2, seed = s)

test_that("baseline-only MC aggregates to an ordered band", {
  mc <- hsrunmc(6, .sfn, .efn, readiness_model = "exponential",
                readiness_half_life_days = 60)
  expect_s3_class(mc, "halo_mc")
  expect_equal(dim(mc$readiness), c(6L, 120L))
  expect_null(mc$readiness_trained)
  expect_null(mc$lift)
  expect_equal(nrow(mc$band), 120L)
  expect_true(all(mc$band$lo <= mc$band$med & mc$band$med <= mc$band$hi))
  expect_length(mc$gap_max, 6L)
  expect_length(mc$gap_max[[1]], 60L)
  expect_equal(nrow(mc$summary), 6L)
})

test_that("same seeds give identical ensembles", {
  a <- hsrunmc(5, .sfn, .efn, readiness_model = "binary")
  b <- hsrunmc(5, .sfn, .efn, readiness_model = "binary")
  expect_identical(a$readiness, b$readiness)
})

test_that("a training program adds a trained arm and positive mean lift", {
  mct <- hsrunmc(6, .sfn, .efn, readiness_model = "exponential",
                 readiness_half_life_days = 60, training_program = "monthly")
  expect_false(is.null(mct$band_trained))
  expect_length(mct$lift, 120L)
  expect_gt(mean(mct$lift), 0)
})

test_that("threshold sweep is derivable from stored gap_max", {
  mc <- hsrunmc(6, .sfn, .efn, readiness_model = "binary")
  all_gap <- unlist(mc$gap_max)
  sweep <- vapply(c(30, 90, 180), function(t) 100 * mean(all_gap > t), numeric(1))
  expect_true(all(diff(sweep) <= 0))
})

test_that("probs must be length 3", {
  expect_error(hsrunmc(2, .sfn, .efn, probs = 0.5), "length 3")
})
