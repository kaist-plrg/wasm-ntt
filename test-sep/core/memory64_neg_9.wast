(assert_invalid
  (module (func (drop (memory.grow (i64.const 0)))))
  "unknown memory"
)
