(assert_invalid
  (module
    (func $type-param-arg-empty-vs-num-in-return (param i32)
      (return (local.tee 0)) (drop)
    )
  )
  "type mismatch"
)
