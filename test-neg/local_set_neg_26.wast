(assert_invalid
  (module (func $type-empty-vs-f32 (param f32) (result f32) (local.set 0 (f32.const 1))))
  "type mismatch"
)
