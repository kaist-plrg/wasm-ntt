(assert_invalid
  (module (table 0 funcref) (table 0 funcref) (export "a" (table 0)) (export "a" (table 1)))
  "duplicate export name"
)
