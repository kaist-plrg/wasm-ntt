(assert_invalid
  (module (table 0 funcref) (global i32 (i32.const 0)) (export "a" (table 0)) (export "a" (global 0)))
  "duplicate export name"
)
