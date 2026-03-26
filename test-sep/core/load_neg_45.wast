(assert_invalid
  (module
    (memory 0)
    (func $type-address-empty-in-load
      (i32.load (i32.load)) (drop)
    )
  )
  "type mismatch"
)
