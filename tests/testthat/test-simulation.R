.sched <- generate_schedule(60, 180, "3/7 Day", seed = 42)
.ev <- generate_events(180, rate = 0.15, seed = 42)

test_that("halo_sim builds a classed object with defaults", {
  sim <- halo_sim(.sched, .ev)
  expect_s3_class(sim, "halo_sim")
  expect_equal(sim$providers[1], "P0001")
  expect_equal(sim$n_providers, 60L)
  expect_null(sim$readiness_matrix)
})

test_that("halo_sim validates inputs", {
  expect_error(halo_sim(as.vector(.sched), .ev), "must be a matrix")
  expect_error(halo_sim(.sched, .ev, providers = c("A", "B")),
               "length\\(providers\\)")
  expect_error(halo_sim(.sched, data.frame(x = 1)), "day_idx")
})

test_that("hsrun produces well-formed outputs", {
  sim <- hsrun(halo_sim(.sched, .ev, readiness_model = "binary",
                        readiness_threshold_days = 90))
  expect_equal(dim(sim$readiness_matrix), c(60L, 180L))
  expect_true(all(sim$readiness_matrix >= 0 & sim$readiness_matrix <= 1))
  expect_equal(nrow(sim$results_df), 60L)
  expect_length(sim$proportion_ready_on_shift, 180L)
  expect_true(all(sim$proportion_ready_on_shift >= 0 &
                    sim$proportion_ready_on_shift <= 1, na.rm = TRUE))
})

test_that("scheduled training resets on cadence and raises readiness", {
  base <- hsrun(halo_sim(.sched, .ev, readiness_model = "exponential",
                         readiness_half_life_days = 60, training_program = "none"))
  train <- hsrun(halo_sim(.sched, .ev, readiness_model = "exponential",
                          readiness_half_life_days = 60, training_program = "monthly"))
  expect_equal(sum(base$training_matrix), 0)
  expect_gt(sum(train$training_matrix), 0)
  expect_gt(mean(train$proportion_ready_on_shift, na.rm = TRUE),
            mean(base$proportion_ready_on_shift, na.rm = TRUE))

  tr_days <- which(colSums(train$training_matrix) > 0)
  expect_true(all((tr_days - 1) %% 30 == 0))  # 0-based day index, monthly = 30
})
