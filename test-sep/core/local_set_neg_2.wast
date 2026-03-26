(assert_invalid
  (module (func $type-local-arg-num-vs-num (local i32) (local.set 0 (f32.const 0))))
  "type mismatch"
)
