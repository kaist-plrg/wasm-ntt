(assert_invalid
  (module (memory i64 0) (func (i32.store16 align=4 (i64.const 0) (i32.const 0))))
  "alignment must not be larger than natural"
)
