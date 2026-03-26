(assert_invalid
  (module
    (memory 0)
    (func $f (param i32) (result i32) (local.get 0))
    (type $sig (func (param i32) (result i32)))
    (table funcref (elem $f))
    (func $type-address-empty-in-call_indirect
      (block (result i32)
        (call_indirect (type $sig)
          (i32.load) (i32.const 0)
        )
        (drop)
      )
    )
  )
  "type mismatch"
)
