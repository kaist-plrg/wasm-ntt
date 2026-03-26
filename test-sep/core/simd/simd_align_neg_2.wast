(assert_invalid
  (module (memory 0) (func(v128.store align=32 (i32.const 0) (v128.const i32x4 0 0 0 0))))
  "alignment must not be larger than natural"
)
