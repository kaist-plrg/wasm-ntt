(assert_invalid
  (module (func (drop (memory.size))))
  "unknown memory"
)
