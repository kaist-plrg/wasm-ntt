(assert_invalid
  (module (memory i64 0) (func (i64.store32 align=8 (i64.const 0) (i64.const 0))))
  "alignment must not be larger than natural"
)
