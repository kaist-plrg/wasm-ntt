(assert_invalid
  (module
    (type $t (func (param i32) (result i64)))
    (func (result i32)
      (unreachable)
      (call_ref $t)
    )
  )
  "type mismatch"
)
