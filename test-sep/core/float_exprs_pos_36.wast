(module
  (func (export "no_fold_demote_promote") (param $x f64) (result f64)
    (f64.promote_f32 (f32.demote_f64 (local.get $x))))
)
