(assert_invalid
  (module (memory 0) (table 0 funcref) (export "a" (memory 0)) (export "a" (table 0)))
  "duplicate export name"
)
