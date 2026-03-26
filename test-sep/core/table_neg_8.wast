(assert_invalid
  (module (table i64 1 0 funcref))
  "size minimum must not be greater than maximum"
)
