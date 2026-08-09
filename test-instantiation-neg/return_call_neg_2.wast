(assert_invalid
  (module
    (func $type-num-vs-num (result i32) (return_call 1) (i32.const 0))
    (func (result i64) (i64.const 1))
  )
  "type mismatch"
)
