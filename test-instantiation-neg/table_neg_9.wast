(assert_invalid
  (module (table i64 0xffff_ffff 0 funcref))
  "size minimum must not be greater than maximum"
)
