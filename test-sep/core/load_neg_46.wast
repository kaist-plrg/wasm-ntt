(assert_invalid
  (module
    (memory 1)
    (func $type-address-empty-in-store
      (i32.store (i32.load) (i32.const 1))
    )
  )
  "type mismatch"
)
