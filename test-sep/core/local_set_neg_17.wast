(assert_invalid
  (module
    (func $type-param-arg-empty-vs-num-in-return (param i32)
      (return (local.set 0))
    )
  )
  "type mismatch"
)
