(assert_invalid
  (module (global i32 (i32.const 0)) (func) (export "a" (global 0)) (export "a" (func 0)))
  "duplicate export name"
)
