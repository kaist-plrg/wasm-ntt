(assert_invalid
  (module (func (select (i32.const 1) (i32.const 1) (f32.const 1)) (drop)))
  "type mismatch"
)
