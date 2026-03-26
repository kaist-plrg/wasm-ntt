(assert_invalid
  (module (func $type-local-arg-void-vs-num (local i32) (local.tee 0 (nop))))
  "type mismatch"
)
