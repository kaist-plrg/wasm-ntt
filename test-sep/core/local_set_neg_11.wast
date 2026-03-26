(assert_invalid
  (module
    (func $type-param-arg-empty-vs-num-in-loop (param i32)
      (i32.const 0)
      (loop (local.set 0))
    )
  )
  "type mismatch"
)
