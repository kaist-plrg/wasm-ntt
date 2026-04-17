(module
  (func (export "f32.no_extended_precision_div") (param $x f32) (param $y f32) (param $z f32) (result i32)
    (f32.eq (f32.div (local.get $x) (local.get $y)) (local.get $z)))

  (func (export "f64.no_extended_precision_div") (param $x f64) (param $y f64) (param $z f64) (result i32)
    (f64.eq (f64.div (local.get $x) (local.get $y)) (local.get $z)))
)
