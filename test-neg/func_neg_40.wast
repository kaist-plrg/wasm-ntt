(assert_invalid
  (module (func $type-break-last-num-vs-num (result i32)
    (br 0 (f32.const 0))
  ))
  "type mismatch"
)
