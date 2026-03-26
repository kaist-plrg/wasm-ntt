(assert_invalid
  (module
    (memory i64 1 1)
    (func (export "testfn")
      (memory.copy (i32.const 10) (i32.const 20) (f32.const 30))))
  "type mismatch")
