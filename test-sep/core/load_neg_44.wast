(assert_invalid
  (module
    (memory 0)
    (func $type-address-empty-in-memory.grow
      (memory.grow (i32.load)) (drop)
    )
  )
  "type mismatch"
)
