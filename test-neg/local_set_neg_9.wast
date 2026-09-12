(assert_invalid
  (module
    (func $type-param-arg-empty-vs-num (param i32)
      (local.set 0)
    )
  )
  "type mismatch"
)
