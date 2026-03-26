(assert_invalid
  (module (memory 1) (func (local v128) (drop (v128.load (f32.const 0)))))
  "type mismatch"
)
