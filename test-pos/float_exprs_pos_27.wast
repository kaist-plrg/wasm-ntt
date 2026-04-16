(module
  (func (export "f32.no_approximate_reciprocal") (param $x f32) (result f32)
    (f32.div (f32.const 1.0) (local.get $x)))
)
