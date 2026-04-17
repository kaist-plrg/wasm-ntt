(module
  (func (export "f32.division_by_small_number")
        (param $a f32) (param $b f32) (param $c f32) (result f32)
    (f32.sub (local.get $a) (f32.div (local.get $b) (local.get $c))))
  (func (export "f64.division_by_small_number")
        (param $a f64) (param $b f64) (param $c f64) (result f64)
    (f64.sub (local.get $a) (f64.div (local.get $b) (local.get $c))))
)
