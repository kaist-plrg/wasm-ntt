(assert_invalid
  (module (memory 1) (func (drop (v128.load align=32 (i32.const 0)))))
  "alignment must not be larger than natural"
)
