(assert_invalid
  (module (func (block $l (f32.neg (br_if $l (i32.const 1))) (nop))))
  "type mismatch"
)
