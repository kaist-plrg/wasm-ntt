(assert_invalid
  (module (func $type-num-vs-num
    (drop (select (i32.const 1) (f64.const 1.0) (i32.const 1)))
  ))
  "type mismatch"
)
