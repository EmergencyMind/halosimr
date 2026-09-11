# Full-pipeline regression test. Pins outputs for fixed seeds so a refactor
# cannot silently change results. The RNG kind is fixed here so the golden
# values hold across R versions (this is already the default since R 3.6; the
# call only guards against a future change to that default).
RNGkind("Mersenne-Twister", "Inversion", "Rejection")

test_that("single exponential run matches golden values", {
  sched <- generate_schedule(30, 90, "3/7 Day", seed = 1)
  ev    <- generate_events(90, rate = 0.2, seed = 1)
  sim <- hsrun(halo_sim(sched, ev, readiness_model = "exponential",
                        readiness_half_life_days = 60,
                        readiness_threshold_days = 90))
  expect_equal(sum(sim$exposure_matrix), 73)
  expect_equal(mean(sim$proportion_ready_on_shift, na.rm = TRUE),
               0.735800697069321, tolerance = 1e-6)
  expect_equal(mean(sim$results_df$gap_max), 61.8333333333333, tolerance = 1e-6)
  expect_equal(sim$readiness_matrix[1, 90], 0.3833320861674, tolerance = 1e-6)
})

test_that("single binary run matches golden value", {
  sched <- generate_schedule(30, 90, "3/7 Day", seed = 1)
  ev    <- generate_events(90, rate = 0.2, seed = 1)
  sim <- hsrun(halo_sim(sched, ev, readiness_model = "binary",
                        readiness_threshold_days = 30))
  expect_equal(mean(sim$proportion_ready_on_shift, na.rm = TRUE),
               0.591177801577698, tolerance = 1e-6)
})

test_that("monte carlo with training matches golden values", {
  mc <- hsrunmc(5,
    function(s) generate_schedule(30, 90, "3/7 Day", seed = s),
    function(s) generate_events(90, rate = 0.2, seed = s),
    readiness_model = "exponential", readiness_half_life_days = 60,
    training_program = "monthly")
  expect_equal(mean(mc$band$med), 0.815184743158087, tolerance = 1e-6)
  expect_equal(mean(mc$band_trained$med), 0.855091407482654, tolerance = 1e-6)
  expect_equal(mean(mc$lift), 0.0399066643245669, tolerance = 1e-6)
})
