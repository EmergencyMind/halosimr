skip_if_not_installed("ggplot2")

.sched <- generate_schedule(60, 180, "3/7 Day", seed = 42)
.ev <- generate_events(180, rate = 0.15, seed = 42)
.sim <- hsrun(halo_sim(.sched, .ev, readiness_model = "exponential",
                       readiness_half_life_days = 60))

test_that("single-run plots return ggplot objects", {
  expect_s3_class(plot_readiness(.sim), "ggplot")
  expect_s3_class(plot_gap_distribution(.sim), "ggplot")
  expect_s3_class(plot_exposure_histogram(.sim), "ggplot")
})

test_that("plots require a run simulation", {
  expect_error(plot_readiness(halo_sim(.sched, .ev)), "Run hsrun")
})

test_that("mc band plots both arms when trained", {
  mc <- hsrunmc(8, function(s) generate_schedule(60, 180, "3/7 Day", seed = s),
                function(s) generate_events(180, rate = 0.15, seed = s),
                readiness_model = "exponential", readiness_half_life_days = 60,
                training_program = "monthly")
  p <- plot_mc_band(mc)
  expect_s3_class(p, "ggplot")
  expect_setequal(unique(p$data$arm), c("baseline", "trained"))
})

test_that("mc band plots one arm when baseline only", {
  mc <- hsrunmc(6, function(s) generate_schedule(60, 180, "3/7 Day", seed = s),
                function(s) generate_events(180, rate = 0.15, seed = s),
                readiness_model = "binary")
  p <- plot_mc_band(mc)
  expect_setequal(unique(p$data$arm), "baseline")
})
