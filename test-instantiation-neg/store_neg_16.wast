(assert_invalid
  (module
    (memory 1)
    (func $type-address-empty-in-then
      (i32.const 0) (i32.const 0)
      (if (then (i32.store)))
    )
  )
  "type mismatch"
)
