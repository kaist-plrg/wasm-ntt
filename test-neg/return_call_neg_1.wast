(assert_invalid
  (module
    (func $type-void-vs-num (result i32) (return_call 1) (i32.const 0))
    (func)
  )
  "type mismatch"
)
