(assert_invalid
  (module (global f32 (f32.const 0)) (func (global.set 0 (f32.const 1))))
  "immutable global"
)
