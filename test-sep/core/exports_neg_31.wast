(assert_invalid
  (module (memory 0) (global i32 (i32.const 0)) (export "a" (memory 0)) (export "a" (global 0)))
  "duplicate export name"
)
