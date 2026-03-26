(assert_invalid
  (module
    (memory 1)
    (func $type-address-empty
      (i32.store)
    )
  )
  "type mismatch"
)
