(module
  (func (export "f32.no_fold_eq_self") (param $x f32) (result i32)
    (f32.eq (local.get $x) (local.get $x)))
  (func (export "f64.no_fold_eq_self") (param $x f64) (result i32)
    (f64.eq (local.get $x) (local.get $x)))
)
