(assert_invalid
  (module
    (memory 1)
    (func $type-address-empty-in-br_if
      (i32.const 0) (i32.const 0)
      (block (br_if 0 (i32.store) (i32.const 1)) )
    )
  )
  "type mismatch"
)
