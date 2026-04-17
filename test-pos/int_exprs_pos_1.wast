(module
  (func (export "i32.no_fold_cmp_s_offset") (param $x i32) (param $y i32) (result i32)
    (i32.lt_s (i32.add (local.get $x) (i32.const 1)) (i32.add (local.get $y) (i32.const 1))))
  (func (export "i32.no_fold_cmp_u_offset") (param $x i32) (param $y i32) (result i32)
    (i32.lt_u (i32.add (local.get $x) (i32.const 1)) (i32.add (local.get $y) (i32.const 1))))

  (func (export "i64.no_fold_cmp_s_offset") (param $x i64) (param $y i64) (result i32)
    (i64.lt_s (i64.add (local.get $x) (i64.const 1)) (i64.add (local.get $y) (i64.const 1))))
  (func (export "i64.no_fold_cmp_u_offset") (param $x i64) (param $y i64) (result i32)
    (i64.lt_u (i64.add (local.get $x) (i64.const 1)) (i64.add (local.get $y) (i64.const 1))))
)
