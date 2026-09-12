(assert_invalid
  (module (func (drop (f32.load (i32.const 0)))))
  "unknown memory"
)
