(assert_invalid
  (module
    (memory 1)
    (func $type-value-empty-in-call
      (call 1 (i32.const 0) (i32.store))
    )
    (func (param i32) (result i32) (local.get 0))
  )
  "type mismatch"
)
