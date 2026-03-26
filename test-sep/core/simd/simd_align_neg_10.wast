(assert_invalid
  (module (memory 1) (func (result v128) (v128.load16_splat align=4 (i32.const 0))))
  "alignment must not be larger than natural"
)
