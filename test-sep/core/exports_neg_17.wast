(assert_invalid
  (module (global i32 (i32.const 0)) (memory 0) (export "a" (global 0)) (export "a" (memory 0)))
  "duplicate export name"
)
