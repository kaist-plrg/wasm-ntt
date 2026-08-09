(assert_invalid
  (module (func $type-empty-vs-i32 (param i32) (result i32) (local.set 0 (i32.const 1))))
  "type mismatch"
)
