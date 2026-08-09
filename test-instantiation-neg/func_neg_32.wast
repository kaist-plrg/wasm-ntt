(assert_invalid
  (module (func $type-return-void-vs-num (result i32)
    (return (nop)) (i32.const 1)
  ))
  "type mismatch"
)
