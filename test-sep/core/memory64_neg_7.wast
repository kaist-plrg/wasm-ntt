(assert_invalid
  (module (func (i32.store8 (i64.const 0) (i32.const 0))))
  "unknown memory"
)
