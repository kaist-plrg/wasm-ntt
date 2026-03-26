(module
  (func (export "f32_sqrt_minus_2") (param $x f32) (result f32)
    (f32.sub (f32.sqrt (local.get $x)) (f32.const 2.0))
  )

  (func (export "f64_sqrt_minus_2") (param $x f64) (result f64)
    (f64.sub (f64.sqrt (local.get $x)) (f64.const 2.0))
  )
)
