(assert_invalid
  (module (func $type-local-num-vs-num (local f32) (i32.eqz (local.tee 0 (f32.const 0)))))
  "type mismatch"
)
