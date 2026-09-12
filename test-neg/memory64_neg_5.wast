(assert_invalid
  (module (func (f32.store (i64.const 0) (f32.const 0))))
  "unknown memory"
)
