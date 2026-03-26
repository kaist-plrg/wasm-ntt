(assert_invalid
  (module (func $type-return-last-void-vs-num (result i32)
    (return (nop))
  ))
  "type mismatch"
)
