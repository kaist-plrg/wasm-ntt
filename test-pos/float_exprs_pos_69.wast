(module
  (func (export "f32.no_fold_add_neg") (param $x f32) (result f32)
    (f32.add (f32.neg (local.get $x)) (local.get $x)))

  (func (export "f64.no_fold_add_neg") (param $x f64) (result f64)
    (f64.add (f64.neg (local.get $x)) (local.get $x)))
)
