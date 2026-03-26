(assert_invalid
  (module (func $type-return-last-empty-vs-nums (result i32 i32)
    (return)
  ))
  "type mismatch"
)
