(assert_invalid
  (module (func) (table 0 funcref) (export "a" (func 0)) (export "a" (table 0)))
  "duplicate export name"
)
