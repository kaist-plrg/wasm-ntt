(module
  (func (export "f32.no_fold_sqrt_square") (param $x f32) (result f32)
    (f32.sqrt (f32.mul (local.get $x) (local.get $x))))

  (func (export "f64.no_fold_sqrt_square") (param $x f64) (result f64)
    (f64.sqrt (f64.mul (local.get $x) (local.get $x))))
)
