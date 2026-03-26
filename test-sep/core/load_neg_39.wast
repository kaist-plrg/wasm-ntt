(assert_invalid
  (module
    (memory 0)
    (func $type-address-empty-in-call
      (call 1 (i32.load)) (drop)
    )
    (func (param i32) (result i32) (local.get 0))
  )
  "type mismatch"
)
