(module
  (func (export "f32.no_fold_neg0_sub") (param $x f32) (result f32)
    (f32.sub (f32.const -0.0) (local.get $x)))
  (func (export "f64.no_fold_neg0_sub") (param $x f64) (result f64)
    (f64.sub (f64.const -0.0) (local.get $x)))
)
