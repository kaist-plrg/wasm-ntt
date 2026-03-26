(assert_invalid
  (module (memory i64 1 0))
  "size minimum must not be greater than maximum"
)
