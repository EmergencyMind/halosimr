test_that("kernels return known values", {
  expect_equal(readiness_binary(c(0, 45, 90, 120), 90), c(1, 1, 1, 0))
  expect_equal(readiness_exponential(c(0, 60, 120), 60), c(1, 0.5, 0.25))
  expect_equal(readiness_ebbinghaus(c(0, 60, 120), 0.05), c(1, 1 / 4, 1 / 7))
  expect_equal(readiness_step(c(0, 90, 150, 200), 90, 180, 0.5), c(1, 1, 0.5, 0))
})

test_that("kernels preserve matrix shape", {
  m <- matrix(c(0, 90, 120, 30, 60, 300), nrow = 2, byrow = TRUE)
  expect_equal(dim(readiness_binary(m, 90)), c(2L, 3L))
  expect_equal(dim(readiness_step(m, 90, 180, 0.5)), c(2L, 3L))
})

test_that("exponential half-life halves readiness", {
  expect_equal(readiness_exponential(60, 60), 0.5)
  expect_equal(readiness_exponential(120, 60), 0.25)
})

test_that("half_life below 1 is floored at 1", {
  expect_equal(readiness_exponential(1, 0.1), exp(-log(2)))
})

test_that("days_since_last_reset tracks the running last reset", {
  # 1 provider, resets at day-index 1 and 3 (0-based): F T F T F
  combined <- matrix(c(FALSE, TRUE, FALSE, TRUE, FALSE), nrow = 1)
  dsl <- halosimr:::days_since_last_reset(combined)
  expect_equal(as.integer(dsl), c(6L, 0L, 1L, 0L, 1L))  # 6 = never (n_days + 1)
})

test_that("days_since_last_reset honours a pre-window reset", {
  combined <- matrix(c(FALSE, TRUE, FALSE, TRUE, FALSE), nrow = 1)
  dsl <- halosimr:::days_since_last_reset(combined, initial_last = -2L)
  expect_equal(as.integer(dsl), c(2L, 0L, 1L, 0L, 1L))
})

test_that("compute_readiness dispatches to the selected model", {
  combined <- matrix(c(FALSE, TRUE, FALSE, TRUE, FALSE), nrow = 1)  # dsl = 6,0,1,0,1
  sim <- list(combined_matrix = combined, readiness_model = "binary",
              readiness_threshold_days = 3)
  expect_equal(as.numeric(halosimr:::compute_readiness(sim)), c(0, 1, 1, 1, 1))

  sim$readiness_model <- "exponential"
  sim$readiness_half_life_days <- 60
  expect_equal(halosimr:::compute_readiness(sim)[1], 2^(-6 / 60))
})
