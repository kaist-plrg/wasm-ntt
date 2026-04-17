(module
  (func (export "f32.epsilon") (result f32)
    (f32.sub (f32.const 1.0) (f32.mul (f32.const 3.0) (f32.sub (f32.div (f32.const 4.0) (f32.const 3.0)) (f32.const 1.0)))))

  (func (export "f64.epsilon") (result f64)
    (f64.sub (f64.const 1.0) (f64.mul (f64.const 3.0) (f64.sub (f64.div (f64.const 4.0) (f64.const 3.0)) (f64.const 1.0)))))
)
