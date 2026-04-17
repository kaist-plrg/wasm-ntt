(module
  (func (export "eq") (param $x v128) (param $y v128) (result v128) (i64x2.eq (local.get $x) (local.get $y)))
  (func (export "ne") (param $x v128) (param $y v128) (result v128) (i64x2.ne (local.get $x) (local.get $y)))
  (func (export "lt_s") (param $x v128) (param $y v128) (result v128) (i64x2.lt_s (local.get $x) (local.get $y)))
  (func (export "le_s") (param $x v128) (param $y v128) (result v128) (i64x2.le_s (local.get $x) (local.get $y)))
  (func (export "gt_s") (param $x v128) (param $y v128) (result v128) (i64x2.gt_s (local.get $x) (local.get $y)))
  (func (export "ge_s") (param $x v128) (param $y v128) (result v128) (i64x2.ge_s (local.get $x) (local.get $y)))
)
