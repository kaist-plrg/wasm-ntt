(module
  (func (export "f32.no_algebraic_factoring") (param $x f32) (param $y f32) (result f32)
    (f32.sub (f32.mul (local.get $x) (local.get $x))
             (f32.mul (local.get $y) (local.get $y))))

  (func (export "f64.no_algebraic_factoring") (param $x f64) (param $y f64) (result f64)
    (f64.sub (f64.mul (local.get $x) (local.get $x))
             (f64.mul (local.get $y) (local.get $y))))
)
