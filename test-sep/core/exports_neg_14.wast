(assert_invalid
  (module (global i32 (i32.const 0)) (global i32 (i32.const 0)) (export "a" (global 0)) (export "a" (global 1)))
  "duplicate export name"
)
