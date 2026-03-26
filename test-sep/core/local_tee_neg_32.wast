(assert_invalid
  (module
    (memory 1)
    (func $type-param-arg-empty-vs-num-in-store (param i32)
      (i32.store (local.tee 0) (i32.const 1))
    )
  )
  "type mismatch"
)
