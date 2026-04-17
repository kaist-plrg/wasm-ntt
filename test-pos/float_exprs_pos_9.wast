(module
  (func (export "f32.no_fold_div_one") (param $x f32) (result f32)
    (f32.div (local.get $x) (f32.const 1.0)))
  (func (export "f64.no_fold_div_one") (param $x f64) (result f64)
    (f64.div (local.get $x) (f64.const 1.0)))
)
