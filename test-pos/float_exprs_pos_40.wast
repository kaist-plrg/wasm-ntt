(module
  (func (export "no_demote_mixed_mul") (param $x f64) (param $y f32) (result f32)
    (f32.demote_f64 (f64.mul (local.get $x) (f64.promote_f32 (local.get $y)))))
  (func (export "no_demote_mixed_mul_commuted") (param $y f32) (param $x f64) (result f32)
    (f32.demote_f64 (f64.mul (f64.promote_f32 (local.get $y)) (local.get $x))))
)
