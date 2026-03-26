(assert_invalid
  (module
    (memory i64 0)
    (func $type-address-empty-in-then
      (i32.const 0) (i32.const 0)
      (if (then (i32.load) (drop)))
    )
  )
  "type mismatch"
)
