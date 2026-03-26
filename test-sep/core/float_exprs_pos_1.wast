(module
  (func (export "f64.no_contraction") (param $x f64) (param $y f64) (param $z f64) (result f64)
    (f64.add (f64.mul (local.get $x) (local.get $y)) (local.get $z)))
)
