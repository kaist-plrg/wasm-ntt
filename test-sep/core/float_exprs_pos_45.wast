(module
  (func (export "f32.ult") (param $x f32) (param $y f32) (result i32) (i32.eqz (f32.ge (local.get $x) (local.get $y))))
  (func (export "f32.ule") (param $x f32) (param $y f32) (result i32) (i32.eqz (f32.gt (local.get $x) (local.get $y))))
  (func (export "f32.ugt") (param $x f32) (param $y f32) (result i32) (i32.eqz (f32.le (local.get $x) (local.get $y))))
  (func (export "f32.uge") (param $x f32) (param $y f32) (result i32) (i32.eqz (f32.lt (local.get $x) (local.get $y))))

  (func (export "f64.ult") (param $x f64) (param $y f64) (result i32) (i32.eqz (f64.ge (local.get $x) (local.get $y))))
  (func (export "f64.ule") (param $x f64) (param $y f64) (result i32) (i32.eqz (f64.gt (local.get $x) (local.get $y))))
  (func (export "f64.ugt") (param $x f64) (param $y f64) (result i32) (i32.eqz (f64.le (local.get $x) (local.get $y))))
  (func (export "f64.uge") (param $x f64) (param $y f64) (result i32) (i32.eqz (f64.lt (local.get $x) (local.get $y))))
)
