(assert_invalid
  (module (table 0 funcref) (memory 0) (export "a" (table 0)) (export "a" (memory 0)))
  "duplicate export name"
)
