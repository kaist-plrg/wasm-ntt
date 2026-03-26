(assert_invalid
  (module (func $type-value-num-vs-nums (result f32 f32)
    (f32.const 0)
  ))
  "type mismatch"
)
