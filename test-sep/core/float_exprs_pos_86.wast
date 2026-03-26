(module
  (func (export "f32.not_lt") (param $x f32) (param $y f32) (result i32)
    (i32.eqz (f32.lt (local.get $x) (local.get $y))))

  (func (export "f32.not_le") (param $x f32) (param $y f32) (result i32)
    (i32.eqz (f32.le (local.get $x) (local.get $y))))

  (func (export "f32.not_gt") (param $x f32) (param $y f32) (result i32)
    (i32.eqz (f32.gt (local.get $x) (local.get $y))))

  (func (export "f32.not_ge") (param $x f32) (param $y f32) (result i32)
    (i32.eqz (f32.ge (local.get $x) (local.get $y))))

  (func (export "f64.not_lt") (param $x f64) (param $y f64) (result i32)
    (i32.eqz (f64.lt (local.get $x) (local.get $y))))

  (func (export "f64.not_le") (param $x f64) (param $y f64) (result i32)
    (i32.eqz (f64.le (local.get $x) (local.get $y))))

  (func (export "f64.not_gt") (param $x f64) (param $y f64) (result i32)
    (i32.eqz (f64.gt (local.get $x) (local.get $y))))

  (func (export "f64.not_ge") (param $x f64) (param $y f64) (result i32)
    (i32.eqz (f64.ge (local.get $x) (local.get $y))))
)
