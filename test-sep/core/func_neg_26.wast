(assert_invalid
  (module (func $type-return-last-void-vs-nums (result i32 i64)
    (return (nop))
  ))
  "type mismatch"
)
