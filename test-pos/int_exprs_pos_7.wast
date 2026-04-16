(module
  (func (export "i32.no_fold_div_s_self") (param $x i32) (result i32)
    (i32.div_s (local.get $x) (local.get $x)))
  (func (export "i32.no_fold_div_u_self") (param $x i32) (result i32)
    (i32.div_u (local.get $x) (local.get $x)))

  (func (export "i64.no_fold_div_s_self") (param $x i64) (result i64)
    (i64.div_s (local.get $x) (local.get $x)))
  (func (export "i64.no_fold_div_u_self") (param $x i64) (result i64)
    (i64.div_u (local.get $x) (local.get $x)))
)
