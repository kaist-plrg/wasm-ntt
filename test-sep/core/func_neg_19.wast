(assert_invalid
  (module (func $type-value-nums-vs-void
    (i32.const 0) (i64.const 0)
  ))
  "type mismatch"
)
