(assert_invalid
  (module
    (memory i64 0)
    (func $type-address-empty-in-loop
      (i32.const 0)
      (loop (i32.load) (drop))
    )
  )
  "type mismatch"
)
