# Fixture: 3 providers x 5 days
#  P1: d o d o d   P2: n n o o o   P3: o o o o o
.schedule <- matrix(c("d", "o", "d", "o", "d",
                      "n", "n", "o", "o", "o",
                      "o", "o", "o", "o", "o"), nrow = 3, byrow = TRUE)
# Day events on day-idx 0 and 2; night event on day-idx 1
.events <- data.frame(day_idx = c(0L, 2L, 1L),
                      shift_type = c("day", "day", "night"),
                      stringsAsFactors = FALSE)

test_that("simple_join is shift-matched", {
  exp <- halosimr:::simple_join(.schedule, .events, 5)
  expect_equal(as.logical(exp[1, ]), c(TRUE, FALSE, TRUE, FALSE, FALSE))
  expect_equal(as.logical(exp[2, ]), c(FALSE, TRUE, FALSE, FALSE, FALSE))
  expect_equal(as.logical(exp[3, ]), c(FALSE, FALSE, FALSE, FALSE, FALSE))
})

test_that("simple_join drops out-of-window events", {
  ev <- data.frame(day_idx = c(-1L, 5L, 0L), shift_type = "day",
                   stringsAsFactors = FALSE)
  exp <- halosimr:::simple_join(.schedule, ev, 5)
  expect_equal(as.logical(exp[1, ]), c(TRUE, FALSE, FALSE, FALSE, FALSE))
})

test_that("gap stats: two exposures give lead-in, between, trail-out", {
  exp <- halosimr:::simple_join(.schedule, .events, 5)
  g <- halosimr:::compute_gaps(exp[1, ], 1, 5)  # exposure days 0,2 -> gaps 0,2,2
  expect_equal(g$n_events, 2L)
  expect_equal(g$t2first, 0L)
  expect_equal(c(g$gap_min, g$gap_median, g$gap_mean, g$gap_max), c(0, 2, 4 / 3, 2))
  expect_equal(c(g$gap_q25, g$gap_q75), c(1, 2))
  expect_true(g$max_gap_exceeds_threshold)
})

test_that("gap stats: one exposure gives two gaps", {
  exp <- halosimr:::simple_join(.schedule, .events, 5)
  g <- halosimr:::compute_gaps(exp[2, ], 1, 5)  # exposure day 1 -> gaps 1,3
  expect_equal(g$n_events, 1L)
  expect_equal(c(g$gap_min, g$gap_max), c(1, 3))
})

test_that("gap stats: zero exposures give a single full-window gap", {
  g <- halosimr:::compute_gaps(rep(FALSE, 5), 1, 5)
  expect_equal(g$n_events, 0L)
  expect_true(is.na(g$t2first))
  expect_equal(c(g$gap_min, g$gap_max), c(5, 5))
})

test_that("compute_exposure returns an ordered per-provider results frame", {
  sim <- list(schedule = .schedule, events = .events,
              providers = c("P1", "P2", "P3"), readiness_threshold_days = 1)
  res <- halosimr:::compute_exposure(sim)
  expect_equal(dim(res$results_df), c(3L, 10L))
  expect_equal(res$results_df$provider_id, c("P1", "P2", "P3"))
  expect_equal(res$results_df$n_events, c(2L, 1L, 0L))
})
