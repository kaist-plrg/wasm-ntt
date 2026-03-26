(assert_invalid
  (module
    (type $t (func (param i32) (result i32 i32)))
    (func (result i32)
      (unreachable)
      (call_ref $t)
    )
  )
  "type mismatch"
)
