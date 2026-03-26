(assert_invalid
  (module
    (memory 0)
    (func $type-address-empty-in-select
      (select (i32.load) (i32.const 1) (i32.const 2)) (drop)
    )
  )
  "type mismatch"
)
