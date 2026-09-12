(assert_invalid
  (module
    (memory i64 0)
    (func $type-address-empty-in-return
      (return (i32.load)) (drop)
    )
  )
  "type mismatch"
)
