(assert_invalid
  (module
    (memory 1)
    (func $type-address-empty-in-block
      (i32.const 0) (i32.const 0)
      (block (i32.store))
    )
  )
  "type mismatch"
)
