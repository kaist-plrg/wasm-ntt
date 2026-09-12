(assert_invalid
  (module (func $type-break-last-num-vs-nums (result i32 i32)
    (br 0 (i32.const 0))
  ))
  "type mismatch"
)
