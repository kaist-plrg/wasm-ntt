(assert_invalid
  (module (memory 0) (func (f32.store align=8 (i32.const 0) (f32.const 0))))
  "alignment must not be larger than natural"
)
