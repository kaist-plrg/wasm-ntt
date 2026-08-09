(assert_invalid
  (module
    (func $type-param-arg-empty-vs-num-in-local.set (param i32)
      (local.set 0 (local.tee 0)) (local.get 0) (drop)
    )
  )
  "type mismatch"
)
