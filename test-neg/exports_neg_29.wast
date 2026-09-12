(assert_invalid
  (module (memory 0) (export "a" (memory 0)) (export "a" (memory 0)))
  "duplicate export name"
)
