(module
  (func (export "f32.no_fold_div_self") (param $x f32) (result f32)
    (f32.div (local.get $x) (local.get $x)))
  (func (export "f64.no_fold_div_self") (param $x f64) (result f64)
    (f64.div (local.get $x) (local.get $x)))
)
