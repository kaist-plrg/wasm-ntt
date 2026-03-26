(module
  (func (export "f32.no_fold_sub_self") (param $x f32) (result f32)
    (f32.sub (local.get $x) (local.get $x)))
  (func (export "f64.no_fold_sub_self") (param $x f64) (result f64)
    (f64.sub (local.get $x) (local.get $x)))
)
