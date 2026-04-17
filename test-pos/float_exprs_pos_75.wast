(module
  (func (export "f32.no_fold_mul_sqrts") (param $x f32) (param $y f32) (result f32)
    (f32.mul (f32.sqrt (local.get $x)) (f32.sqrt (local.get $y))))

  (func (export "f64.no_fold_mul_sqrts") (param $x f64) (param $y f64) (result f64)
    (f64.mul (f64.sqrt (local.get $x)) (f64.sqrt (local.get $y))))
)
