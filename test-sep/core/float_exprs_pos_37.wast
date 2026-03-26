(module
  (func (export "no_fold_promote_demote") (param $x f32) (result f32)
    (f32.demote_f64 (f64.promote_f32 (local.get $x))))
)
