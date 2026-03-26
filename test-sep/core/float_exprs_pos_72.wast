(module
  (func (export "f32.no_fold_mul_divs") (param $x f32) (param $y f32) (param $z f32) (param $w f32) (result f32)
    (f32.mul (f32.div (local.get $x) (local.get $y)) (f32.div (local.get $z) (local.get $w))))

  (func (export "f64.no_fold_mul_divs") (param $x f64) (param $y f64) (param $z f64) (param $w f64) (result f64)
    (f64.mul (f64.div (local.get $x) (local.get $y)) (f64.div (local.get $z) (local.get $w))))
)
