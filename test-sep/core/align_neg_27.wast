(assert_invalid
  (module (memory 0) (func (drop (f32.load align=8 (i32.const 0)))))
  "alignment must not be larger than natural"
)
