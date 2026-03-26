(assert_invalid
  (module
    (memory i64 0)
    (func $type-address-empty-in-block
      (i32.const 0)
      (block (i32.load) (drop))
    )
  )
  "type mismatch"
)
