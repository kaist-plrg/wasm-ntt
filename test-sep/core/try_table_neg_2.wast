(assert_invalid
  (module (func (result i32) (try_table (result i32) (i64.const 42))))
  "type mismatch"
)
