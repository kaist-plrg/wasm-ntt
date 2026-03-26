(module
  (func (export "thepast0") (param $a f64) (param $b f64) (param $c f64) (param $d f64) (result f64)
    (f64.div (f64.mul (local.get $a) (local.get $b)) (f64.mul (local.get $c) (local.get $d)))
  )

  (func (export "thepast1") (param $a f64) (param $b f64) (param $c f64) (result f64)
    (f64.sub (f64.mul (local.get $a) (local.get $b)) (local.get $c))
  )

  (func (export "thepast2") (param $a f32) (param $b f32) (param $c f32) (result f32)
    (f32.mul (f32.mul (local.get $a) (local.get $b)) (local.get $c))
  )
)
