(assert_invalid
  (module (func $type-num-vs-num (select (i32.const 1) (f32.const 1.0) (i32.const 1)) (drop)))
  "type mismatch"
)
