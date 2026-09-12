(assert_invalid
  (module
    (func $type-param-arg-empty-vs-num-in-select (param i32)
      (select (local.set 0) (i32.const 1) (i32.const 2))
    )
  )
  "type mismatch"
)
