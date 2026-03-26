(assert_invalid
  (module (func) (memory 0) (export "a" (func 0)) (export "a" (memory 0)))
  "duplicate export name"
)
