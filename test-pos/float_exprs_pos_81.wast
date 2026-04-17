(module
  (func (export "f32.no_distribute_exact") (param $x f32) (result f32)
    (f32.add (f32.mul (f32.const -8.0) (local.get $x)) (f32.mul (f32.const 8.0) (local.get $x))))

  (func (export "f64.no_distribute_exact") (param $x f64) (result f64)
    (f64.add (f64.mul (f64.const -8.0) (local.get $x)) (f64.mul (f64.const 8.0) (local.get $x))))
)
