(assert_invalid
  (module (func $type-return-last-num-vs-num (result i32)
    (return (i64.const 0))
  ))
  "type mismatch"
)
