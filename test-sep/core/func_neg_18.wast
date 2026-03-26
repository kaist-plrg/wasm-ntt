(assert_invalid
  (module (func $type-value-num-vs-void
    (i32.const 0)
  ))
  "type mismatch"
)
