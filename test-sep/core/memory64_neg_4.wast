(assert_invalid
  (module (func (drop (f32.load (i64.const 0)))))
  "unknown memory"
)
