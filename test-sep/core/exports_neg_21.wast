(assert_invalid
  (module (table 0 funcref) (export "a" (table 0)) (export "a" (table 0)))
  "duplicate export name"
)
