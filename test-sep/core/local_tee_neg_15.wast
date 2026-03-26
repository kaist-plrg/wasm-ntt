(assert_invalid
  (module
    (func $type-param-arg-empty-vs-num (param i32)
      (local.tee 0) (drop)
    )
  )
  "type mismatch"
)
