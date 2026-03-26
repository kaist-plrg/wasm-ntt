(assert_invalid
  (module (memory 0) (func (f64.store align=16 (i32.const 0) (f64.const 0))))
  "alignment must not be larger than natural"
)
