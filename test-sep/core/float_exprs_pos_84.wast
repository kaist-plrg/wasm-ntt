(module
  (func (export "f32.no_fold_sub1_mul_add") (param $x f32) (param $y f32) (result f32)
    (f32.add (f32.mul (f32.sub (local.get $x) (f32.const 1.0)) (local.get $y)) (local.get $y)))

  (func (export "f64.no_fold_sub1_mul_add") (param $x f64) (param $y f64) (result f64)
    (f64.add (f64.mul (f64.sub (local.get $x) (f64.const 1.0)) (local.get $y)) (local.get $y)))
)
