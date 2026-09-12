(assert_invalid
  (module
    (memory i64 0)
    (func $type-address-empty-in-br_table
      (i32.const 0)
      (block (br_table 0 (i32.load)) (drop))
    )
  )
  "type mismatch"
)
