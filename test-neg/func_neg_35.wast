(assert_invalid
  (module (func $type-return-num-vs-nums (result i32 i32)
    (return (i64.const 1)) (i32.const 1) (i32.const 2)
  ))
  "type mismatch"
)
