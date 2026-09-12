(assert_invalid
  (module
    (memory i64 0)
    (func $type-address-empty-in-br
      (i32.const 0)
      (block (br 0 (i32.load)) (drop))
    )
  )
  "type mismatch"
)
