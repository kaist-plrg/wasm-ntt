(assert_invalid
  (module (func $type-num-vs-num (select (i32.const 1) (i64.const 1) (i32.const 1)) (drop)))
  "type mismatch"
)
