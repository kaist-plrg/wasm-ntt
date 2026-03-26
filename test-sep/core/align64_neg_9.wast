(assert_invalid
  (module (memory i64 0) (func (drop (i64.load16_u align=4 (i64.const 0)))))
  "alignment must not be larger than natural"
)
