(assert_invalid
  (module
    (memory i64 0)
    (func $type-address-empty-in-br_if
      (i32.const 0)
      (block (br_if 0 (i32.load) (i32.const 1)) (drop))
    )
  )
  "type mismatch"
)
