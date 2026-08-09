(assert_invalid
  (module (table 0 funcref) (func) (export "a" (table 0)) (export "a" (func 0)))
  "duplicate export name"
)
