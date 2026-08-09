(assert_invalid
  (module
    (memory 1)
    (func $type-address-empty-in-select
      (select (i32.store) (i32.const 1) (i32.const 2))
    )
  )
  "type mismatch"
)
