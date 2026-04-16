(module
  (func (export "eq") (param $x v128) (param $y v128) (result v128) (f32x4.eq (local.get $x) (local.get $y)))
  (func (export "ne") (param $x v128) (param $y v128) (result v128) (f32x4.ne (local.get $x) (local.get $y)))
  (func (export "lt") (param $x v128) (param $y v128) (result v128) (f32x4.lt (local.get $x) (local.get $y)))
  (func (export "le") (param $x v128) (param $y v128) (result v128) (f32x4.le (local.get $x) (local.get $y)))
  (func (export "gt") (param $x v128) (param $y v128) (result v128) (f32x4.gt (local.get $x) (local.get $y)))
  (func (export "ge") (param $x v128) (param $y v128) (result v128) (f32x4.ge (local.get $x) (local.get $y)))
)
