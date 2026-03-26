(assert_invalid
  (module
    (memory 0)
    (func $type-address-empty-in-block
      (i32.const 0)
      (block (i32.load) (drop))
    )
  )
  "type mismatch"
)
