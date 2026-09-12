(assert_invalid
  (module (func $type-param-arg-void-vs-num (param i32) (local.set 0 (nop))))
  "type mismatch"
)
