(assert_invalid
  (module (memory 0) (func (i64.store8 align=2 (i32.const 0) (i64.const 0))))
  "alignment must not be larger than natural"
)
