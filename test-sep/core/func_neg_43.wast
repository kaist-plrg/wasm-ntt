(assert_invalid
  (module (func $type-break-void-vs-nums (result i32 i32)
    (br 0) (i32.const 1) (i32.const 2)
  ))
  "type mismatch"
)
