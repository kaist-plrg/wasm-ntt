(module
  (func (export "no_demote_mixed_div") (param $x f64) (param $y f32) (result f32)
    (f32.demote_f64 (f64.div (local.get $x) (f64.promote_f32 (local.get $y)))))
  (func (export "no_demote_mixed_div_commuted") (param $y f32) (param $x f64) (result f32)
    (f32.demote_f64 (f64.div (f64.promote_f32 (local.get $y)) (local.get $x))))
)
