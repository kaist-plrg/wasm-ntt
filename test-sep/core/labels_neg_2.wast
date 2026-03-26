(assert_invalid
  (module (func (block $l (br_if $l (f32.const 0) (i32.const 1)))))
  "type mismatch"
)
