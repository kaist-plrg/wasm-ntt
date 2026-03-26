(assert_invalid
  (module (func $type-break-void-vs-num (result i32)
    (br 0) (i32.const 1)
  ))
  "type mismatch"
)
