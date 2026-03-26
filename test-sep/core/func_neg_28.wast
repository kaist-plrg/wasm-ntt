(assert_invalid
  (module (func $type-return-last-num-vs-nums (result i64 i64)
    (return (i64.const 0))
  ))
  "type mismatch"
)
