(module
  (func (export "f32.no_fold_neg1_mul") (param $x f32) (result f32)
    (f32.mul (f32.const -1.0) (local.get $x)))
  (func (export "f64.no_fold_neg1_mul") (param $x f64) (result f64)
    (f64.mul (f64.const -1.0) (local.get $x)))
)
