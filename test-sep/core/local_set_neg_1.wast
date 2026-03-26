(assert_invalid
  (module (func $type-local-arg-void-vs-num (local i32) (local.set 0 (nop))))
  "type mismatch"
)
