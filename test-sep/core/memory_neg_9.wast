(assert_invalid
  (module (func (drop (memory.grow (i32.const 0)))))
  "unknown memory"
)
