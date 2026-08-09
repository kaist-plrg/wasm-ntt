(assert_invalid
  (module
    (memory i64 0)
    (func $type-address-empty-in-memory.grow
      (memory.grow (i64.load)) (drop)
    )
  )
  "type mismatch"
)
