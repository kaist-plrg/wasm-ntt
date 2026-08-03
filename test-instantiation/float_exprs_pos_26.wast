(module
  (func (export "f32.no_fold_to_hypot") (param $x f32) (param $y f32) (result f32)
    (f32.sqrt (f32.add (f32.mul (local.get $x) (local.get $x))
                       (f32.mul (local.get $y) (local.get $y)))))
  (func (export "f64.no_fold_to_hypot") (param $x f64) (param $y f64) (result f64)
    (f64.sqrt (f64.add (f64.mul (local.get $x) (local.get $x))
                       (f64.mul (local.get $y) (local.get $y)))))
)
