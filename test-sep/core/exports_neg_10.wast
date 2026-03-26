(assert_invalid
  (module (export "a" (global 0)))
  "unknown global"
)
