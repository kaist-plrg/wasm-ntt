(assert_invalid
  (module (memory i64 0) (func (drop (f64.load align=16 (i64.const 0)))))
  "alignment must not be larger than natural"
)
