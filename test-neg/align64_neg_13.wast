(assert_invalid
  (module (memory i64 0) (func (drop (f32.load align=8 (i64.const 0)))))
  "alignment must not be larger than natural"
)
