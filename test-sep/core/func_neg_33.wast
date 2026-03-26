(assert_invalid
  (module (func $type-return-void-vs-nums (result i32 i32)
    (return (nop)) (i32.const 1)
  ))
  "type mismatch"
)
