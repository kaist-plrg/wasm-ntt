(module
  (func (export "i32.no_fold_div_neg1") (param $x i32) (result i32)
    (i32.div_s (local.get $x) (i32.const -1)))

  (func (export "i64.no_fold_div_neg1") (param $x i64) (result i64)
    (i64.div_s (local.get $x) (i64.const -1)))
)
