(module
  (func (export "f32.no_regroup_div_mul") (param $x f32) (param $y f32) (param $z f32) (result f32)
    (f32.mul (local.get $x) (f32.div (local.get $y) (local.get $z))))
  (func (export "f64.no_regroup_div_mul") (param $x f64) (param $y f64) (param $z f64) (result f64)
    (f64.mul (local.get $x) (f64.div (local.get $y) (local.get $z))))
)
