(module
  (func (export "f32.no_fold_recip_recip") (param $x f32) (result f32)
    (f32.div (f32.const 1.0) (f32.div (f32.const 1.0) (local.get $x))))

  (func (export "f64.no_fold_recip_recip") (param $x f64) (result f64)
    (f64.div (f64.const 1.0) (f64.div (f64.const 1.0) (local.get $x))))
)
