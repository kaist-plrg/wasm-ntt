(assert_invalid
  (module
    (func $type-param-arg-empty-vs-num-in-then (param i32)
      (i32.const 0) (i32.const 0)
      (if (then (local.tee 0) (drop)))
    )
  )
  "type mismatch"
)
