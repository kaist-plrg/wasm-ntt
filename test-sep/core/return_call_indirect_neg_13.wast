(assert_invalid
  (module
  (type (func))
  (table 10 externref)
  (func $return-call-indirect (return_call_indirect (type 0) (i32.const 0)))
  )
  "type mismatch"
)
