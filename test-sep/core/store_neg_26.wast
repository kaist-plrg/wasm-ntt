(assert_invalid
  (module
    (memory 1)
    (func $type-address-empty-in-return
      (return (i32.store))
    )
  )
  "type mismatch"
)
