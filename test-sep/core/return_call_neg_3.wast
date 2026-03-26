(assert_invalid
  (module
    (func $arity-0-vs-1 (return_call 1))
    (func (param i32))
  )
  "type mismatch"
)
