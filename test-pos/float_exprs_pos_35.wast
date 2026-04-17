(module
  (func (export "f32.no_fold_div2_mul2") (param $x f32) (result f32)
    (f32.mul (f32.div (local.get $x) (f32.const 2.0)) (f32.const 2.0)))
  (func (export "f64.no_fold_div2_mul2") (param $x f64) (result f64)
    (f64.mul (f64.div (local.get $x) (f64.const 2.0)) (f64.const 2.0)))
)
