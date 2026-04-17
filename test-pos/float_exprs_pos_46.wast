(module
  (func (export "f32.no_fold_lt_select") (param $x f32) (param $y f32) (result f32) (select (local.get $x) (local.get $y) (f32.lt (local.get $x) (local.get $y))))
  (func (export "f32.no_fold_le_select") (param $x f32) (param $y f32) (result f32) (select (local.get $x) (local.get $y) (f32.le (local.get $x) (local.get $y))))
  (func (export "f32.no_fold_gt_select") (param $x f32) (param $y f32) (result f32) (select (local.get $x) (local.get $y) (f32.gt (local.get $x) (local.get $y))))
  (func (export "f32.no_fold_ge_select") (param $x f32) (param $y f32) (result f32) (select (local.get $x) (local.get $y) (f32.ge (local.get $x) (local.get $y))))

  (func (export "f64.no_fold_lt_select") (param $x f64) (param $y f64) (result f64) (select (local.get $x) (local.get $y) (f64.lt (local.get $x) (local.get $y))))
  (func (export "f64.no_fold_le_select") (param $x f64) (param $y f64) (result f64) (select (local.get $x) (local.get $y) (f64.le (local.get $x) (local.get $y))))
  (func (export "f64.no_fold_gt_select") (param $x f64) (param $y f64) (result f64) (select (local.get $x) (local.get $y) (f64.gt (local.get $x) (local.get $y))))
  (func (export "f64.no_fold_ge_select") (param $x f64) (param $y f64) (result f64) (select (local.get $x) (local.get $y) (f64.ge (local.get $x) (local.get $y))))
)
