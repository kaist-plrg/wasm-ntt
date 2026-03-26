(assert_invalid
  (module
    (func $type-param-arg-empty-vs-num-in-then (param i32)
      (i32.const 0)
      (if (i32.const 1) (then (local.set 0)))
    )
  )
  "type mismatch"
)
