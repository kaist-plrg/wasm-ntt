(assert_invalid
  (module (memory 0) (func (drop (i32.load16_s align=4 (i32.const 0)))))
  "alignment must not be larger than natural"
)
