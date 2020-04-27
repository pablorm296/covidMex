# Error test (wrapper)
test_that("Errors due to missing or malformed parameters in main wrappers", {
  expect_error(
    getData()
  )
})
