(assert_invalid
  (module (func (select (i32.const 1) (i32.const 1) (f64.const 1)) (drop)))
  "type mismatch"
)
