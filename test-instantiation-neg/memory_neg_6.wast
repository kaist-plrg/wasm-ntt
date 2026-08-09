(assert_invalid
  (module (func (drop (i32.load8_s (i32.const 0)))))
  "unknown memory"
)
