(assert_invalid
  (module
    (func $type-param-arg-empty-vs-num-in-block (param i32)
      (i32.const 0)
      (block (local.set 0))
    )
  )
  "type mismatch"
)
