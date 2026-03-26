(assert_invalid
  (module (memory 1) (func (local v128) (v128.load (i32.const 0))))
  "type mismatch"
)
