(assert_invalid
  (module (func $type-return-partial-vs-nums (result i32 i32)
    (i32.const 1) (return) (i32.const 2)
  ))
  "type mismatch"
)
