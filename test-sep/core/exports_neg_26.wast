(assert_invalid
  (module (export "a" (memory 0)))
  "unknown memory"
)
