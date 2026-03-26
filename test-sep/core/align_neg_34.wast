(assert_invalid
  (module (memory 0) (func (i64.store32 align=8 (i32.const 0) (i64.const 0))))
  "alignment must not be larger than natural"
)
