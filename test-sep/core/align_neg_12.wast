(assert_invalid
  (module (memory 0) (func (drop (i64.load align=16 (i32.const 0)))))
  "alignment must not be larger than natural"
)
