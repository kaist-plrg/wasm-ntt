(module
  (func (export "f32.no_fold_add_sub") (param $x f32) (param $y f32) (result f32)
    (f32.sub (f32.add (local.get $x) (local.get $y)) (local.get $y)))
  (func (export "f64.no_fold_add_sub") (param $x f64) (param $y f64) (result f64)
    (f64.sub (f64.add (local.get $x) (local.get $y)) (local.get $y)))
)
