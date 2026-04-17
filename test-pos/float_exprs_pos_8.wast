(module
  (func (export "f32.no_fold_zero_div") (param $x f32) (result f32)
    (f32.div (f32.const 0.0) (local.get $x)))
  (func (export "f64.no_fold_zero_div") (param $x f64) (result f64)
    (f64.div (f64.const 0.0) (local.get $x)))
)
