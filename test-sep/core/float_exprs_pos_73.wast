(module
  (func (export "f32.no_fold_add_divs") (param $x f32) (param $y f32) (param $z f32) (result f32)
    (f32.add (f32.div (local.get $x) (local.get $z)) (f32.div (local.get $y) (local.get $z))))

  (func (export "f64.no_fold_add_divs") (param $x f64) (param $y f64) (param $z f64) (result f64)
    (f64.add (f64.div (local.get $x) (local.get $z)) (f64.div (local.get $y) (local.get $z))))
)
