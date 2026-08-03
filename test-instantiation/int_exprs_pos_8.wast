(module
  (func (export "i32.no_fold_rem_s_self") (param $x i32) (result i32)
    (i32.rem_s (local.get $x) (local.get $x)))
  (func (export "i32.no_fold_rem_u_self") (param $x i32) (result i32)
    (i32.rem_u (local.get $x) (local.get $x)))

  (func (export "i64.no_fold_rem_s_self") (param $x i64) (result i64)
    (i64.rem_s (local.get $x) (local.get $x)))
  (func (export "i64.no_fold_rem_u_self") (param $x i64) (result i64)
    (i64.rem_u (local.get $x) (local.get $x)))
)
