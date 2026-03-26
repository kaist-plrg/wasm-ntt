(assert_invalid
  (module (func $type-break-last-void-vs-num (result i32)
    (br 0)
  ))
  "type mismatch"
)
