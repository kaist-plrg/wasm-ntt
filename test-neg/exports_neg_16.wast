(assert_invalid
  (module (global i32 (i32.const 0)) (table 0 funcref) (export "a" (global 0)) (export "a" (table 0)))
  "duplicate export name"
)
