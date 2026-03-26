(module
  (func (export "f32.no_reassociate_mul") (param $x f32) (param $y f32) (param $z f32) (param $w f32) (result f32)
    (f32.mul (f32.mul (f32.mul (local.get $x) (local.get $y)) (local.get $z)) (local.get $w)))
  (func (export "f64.no_reassociate_mul") (param $x f64) (param $y f64) (param $z f64) (param $w f64) (result f64)
    (f64.mul (f64.mul (f64.mul (local.get $x) (local.get $y)) (local.get $z)) (local.get $w)))
)
