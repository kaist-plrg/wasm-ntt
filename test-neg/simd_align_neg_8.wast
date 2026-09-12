(assert_invalid
  (module (memory 1) (func (result v128) (v128.load32x2_u align=16 (i32.const 0))))
  "alignment must not be larger than natural"
)
