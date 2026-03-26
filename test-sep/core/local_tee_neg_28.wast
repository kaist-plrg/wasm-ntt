(assert_invalid
  (module
    (func $type-param-arg-empty-vs-num-in-local.tee (param i32)
      (local.tee 0 (local.tee 0)) (drop)
    )
  )
  "type mismatch"
)
