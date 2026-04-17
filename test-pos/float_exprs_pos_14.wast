(module
  (func (export "f32.no_fold_ne_self") (param $x f32) (result i32)
    (f32.ne (local.get $x) (local.get $x)))
  (func (export "f64.no_fold_ne_self") (param $x f64) (result i32)
    (f64.ne (local.get $x) (local.get $x)))
)
