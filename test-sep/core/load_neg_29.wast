(assert_invalid
  (module
    (memory 0)
    (func $type-address-empty
      (i32.load) (drop)
    )
  )
  "type mismatch"
)
