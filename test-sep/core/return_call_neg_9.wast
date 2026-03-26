(assert_invalid
  (module
    (func $f (result i32 i32) unreachable)
    (func (result i32)
      return_call $f
    )
  )
  "type mismatch"
)
