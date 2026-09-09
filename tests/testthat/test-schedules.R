test_that("generation is reproducible and well-formed", {
  s1 <- generate_schedule(50, 84, "3/7 Day", seed = 7)
  s2 <- generate_schedule(50, 84, "3/7 Day", seed = 7)
  expect_identical(s1, s2)
  expect_equal(dim(s1), c(50L, 84L))
  expect_true(all(s1 %in% c("d", "n", "o")))
})

test_that("k/7 types place the right count of the right shift", {
  s3 <- generate_schedule(50, 84, "3/7 Day", seed = 7)   # 12 weeks x 3
  expect_equal(sum(s3 == "n"), 0)
  expect_true(all(abs(rowSums(s3 == "d") - 36) <= 2))

  s4 <- generate_schedule(50, 84, "4/7 Night", seed = 7) # 12 weeks x 4
  expect_equal(sum(s4 == "d"), 0)
  expect_true(all(rowSums(s4 == "n") == 48))
})

test_that("Random tracks paper weights; weights overrides to any split", {
  sr <- generate_schedule(400, 365, "Random", seed = 3)
  p <- prop.table(table(factor(sr, c("d", "n", "o"))))
  expect_lt(abs(p["d"] - 0.246), 0.02)
  expect_lt(abs(p["n"] - 0.230), 0.02)
  expect_lt(abs(p["o"] - 0.524), 0.02)

  se <- generate_schedule(400, 365, "Random", seed = 3,
                          weights = c(d = 1/3, n = 1/3, o = 1/3))
  pe <- prop.table(table(factor(se, c("d", "n", "o"))))
  expect_true(all(abs(pe - 1/3) < 0.02))
})

test_that("pattern tiles across the window, identical per provider", {
  sp <- schedule_from_pattern(3, 56, "dddoooonnnooooo")
  expect_identical(as.character(sp[1, ]), as.character(sp[2, ]))
  expect_true(all(sp[1, 1:3] == "d"))
  expect_equal(sp[1, 29], sp[1, 1])  # 28-day tile
})

test_that("load_schedule normalises codes and fills missing days off", {
  df <- data.frame(provider_id = c("A", "A", "B"),
                   date = c("2024-01-01", "2024-01-03", "2024-01-02"),
                   shift_type = c("day", "n", "off"), stringsAsFactors = FALSE)
  ls <- suppressWarnings(load_schedule(df, n_days = 5, start_date = "2024-01-01"))
  expect_identical(ls$providers, c("A", "B"))
  expect_equal(ls$schedule[1, 1], "d")
  expect_equal(ls$schedule[1, 3], "n")
  expect_equal(ls$schedule[2, 2], "o")
  expect_equal(ls$schedule[1, 2], "o")
})

test_that("load_schedule rejects missing columns and bad codes", {
  expect_error(load_schedule(data.frame(provider_id = "A", date = "2024-01-01"),
                             n_days = 5), "Missing required column")
  bad <- data.frame(provider_id = "A", date = "2024-01-01", shift_type = "swing")
  expect_error(load_schedule(bad, n_days = 5), "Invalid shift_type")
})
