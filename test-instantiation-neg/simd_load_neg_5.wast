(assert_invalid
  (module (memory 1) (func (drop (v128.load))))
  "type mismatch"
)
