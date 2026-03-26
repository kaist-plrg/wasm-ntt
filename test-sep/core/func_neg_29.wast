(assert_invalid
  (module (func $type-return-empty-vs-num (result i32)
    (return) (i32.const 1)
  ))
  "type mismatch"
)
