(assert_invalid
  (module (func (result i32) (select (i64.const 1) (i64.const 1) (i32.const 1))))
  "type mismatch"
)
