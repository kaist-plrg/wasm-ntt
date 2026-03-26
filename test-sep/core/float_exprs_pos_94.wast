(module
  (func (export "f32.golden_ratio") (param $a f32) (param $b f32) (param $c f32) (result f32)
    (f32.mul (local.get 0) (f32.add (local.get 1) (f32.sqrt (local.get 2)))))
  (func (export "f64.golden_ratio") (param $a f64) (param $b f64) (param $c f64) (result f64)
    (f64.mul (local.get 0) (f64.add (local.get 1) (f64.sqrt (local.get 2)))))
)
