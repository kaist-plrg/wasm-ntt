(module
  (func (export "f32.no_reassociate_add") (param $x f32) (param $y f32) (param $z f32) (param $w f32) (result f32)
    (f32.add (f32.add (f32.add (local.get $x) (local.get $y)) (local.get $z)) (local.get $w)))
  (func (export "f64.no_reassociate_add") (param $x f64) (param $y f64) (param $z f64) (param $w f64) (result f64)
    (f64.add (f64.add (f64.add (local.get $x) (local.get $y)) (local.get $z)) (local.get $w)))
)
