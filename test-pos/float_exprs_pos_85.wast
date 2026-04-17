(module
  (func (export "f32.no_fold_add_le_monotonicity") (param $x f32) (param $y f32) (param $z f32) (result i32)
    (f32.le (f32.add (local.get $x) (local.get $z)) (f32.add (local.get $y) (local.get $z))))

  (func (export "f32.no_fold_add_ge_monotonicity") (param $x f32) (param $y f32) (param $z f32) (result i32)
    (f32.ge (f32.add (local.get $x) (local.get $z)) (f32.add (local.get $y) (local.get $z))))

  (func (export "f64.no_fold_add_le_monotonicity") (param $x f64) (param $y f64) (param $z f64) (result i32)
    (f64.le (f64.add (local.get $x) (local.get $z)) (f64.add (local.get $y) (local.get $z))))

  (func (export "f64.no_fold_add_ge_monotonicity") (param $x f64) (param $y f64) (param $z f64) (result i32)
    (f64.ge (f64.add (local.get $x) (local.get $z)) (f64.add (local.get $y) (local.get $z))))
)
