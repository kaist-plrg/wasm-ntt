(assert_invalid
  (module (func $type-mixed-arg-num-vs-num (param i64 i32) (local f32) (local.set 1 (f32.const 0))))
  "type mismatch"
)
