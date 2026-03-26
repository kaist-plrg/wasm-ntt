(module
  (func (export "f32.no_fold_mul_sqrt_div") (param $x f32) (param $y f32) (result f32)
    (f32.div (f32.mul (local.get $x) (f32.sqrt (local.get $y))) (local.get $y)))

  (func (export "f64.no_fold_mul_sqrt_div") (param $x f64) (param $y f64) (result f64)
    (f64.div (f64.mul (local.get $x) (f64.sqrt (local.get $y))) (local.get $y)))
)
