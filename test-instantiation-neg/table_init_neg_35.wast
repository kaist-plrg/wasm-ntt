(assert_invalid
  (module
    (table 10 funcref)
    (elem funcref (ref.func $f0) (ref.func $f0) (ref.func $f0))
    (func $f0)
    (func (export "test")
      (table.init 0 (f32.const 1) (f64.const 1) (f64.const 1))))
  "type mismatch")
