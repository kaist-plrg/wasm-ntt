(module
  (func (export "f32.no_fold_6x_via_add") (param $x f32) (result f32)
    (f32.add (f32.add (f32.add (f32.add (f32.add
    (local.get $x)
    (local.get $x)) (local.get $x)) (local.get $x))
    (local.get $x)) (local.get $x)))

  (func (export "f64.no_fold_6x_via_add") (param $x f64) (result f64)
    (f64.add (f64.add (f64.add (f64.add (f64.add
    (local.get $x)
    (local.get $x)) (local.get $x)) (local.get $x))
    (local.get $x)) (local.get $x)))
)
