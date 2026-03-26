(assert_invalid
  (module (memory 0) (export "a" (memory 1)))
  "unknown memory"
)
