(assert_invalid
  (module
    (func $f (param i32) (result i32) (local.get 0))
    (type $sig (func (param i32) (result i32)))
    (table funcref (elem $f))
    (func $type-param-arg-empty-vs-num-in-call_indirect (param i32)
      (block (result i32)
        (call_indirect (type $sig)
          (local.set 0) (i32.const 0)
        )
      )
    )
  )
  "type mismatch"
)
