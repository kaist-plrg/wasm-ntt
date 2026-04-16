(module
  (func (export "f32.no_approximate_reciprocal_sqrt") (param $x f32) (result f32)
    (f32.div (f32.const 1.0) (f32.sqrt (local.get $x))))
  (func (export "f64.no_fuse_reciprocal_sqrt") (param $x f64) (result f64)
    (f64.div (f64.const 1.0) (f64.sqrt (local.get $x))))
)
