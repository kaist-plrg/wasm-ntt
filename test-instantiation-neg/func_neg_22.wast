(assert_invalid
  (module (func $type-value-nums-vs-num (result f32)
    (f32.const 0) (f32.const 0)
  ))
  "type mismatch"
)
