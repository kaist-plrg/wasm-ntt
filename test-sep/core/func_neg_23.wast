(assert_invalid
  (module (func $type-return-last-empty-vs-num (result i32)
    (return)
  ))
  "type mismatch"
)
