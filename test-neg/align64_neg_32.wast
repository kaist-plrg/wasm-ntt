(assert_invalid
  (module (memory i64 0) (func (i64.store8 align=2 (i64.const 0) (i64.const 0))))
  "alignment must not be larger than natural"
)
