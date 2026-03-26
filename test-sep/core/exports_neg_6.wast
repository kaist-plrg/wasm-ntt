(assert_invalid
  (module (func) (global i32 (i32.const 0)) (export "a" (func 0)) (export "a" (global 0)))
  "duplicate export name"
)
