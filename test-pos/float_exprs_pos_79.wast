(module
  (func (export "f32.recoding_eq") (param $x f32) (param $y f32) (result i32)
    (f32.eq (f32.mul (local.get $x) (local.get $y)) (local.get $x)))

  (func (export "f32.recoding_le") (param $x f32) (param $y f32) (result i32)
    (f32.le (f32.mul (local.get $x) (local.get $y)) (local.get $x)))

  (func (export "f32.recoding_lt") (param $x f32) (param $y f32) (result i32)
    (f32.lt (f32.mul (local.get $x) (local.get $y)) (local.get $x)))

  (func (export "f64.recoding_eq") (param $x f64) (param $y f64) (result i32)
    (f64.eq (f64.mul (local.get $x) (local.get $y)) (local.get $x)))

  (func (export "f64.recoding_le") (param $x f64) (param $y f64) (result i32)
    (f64.le (f64.mul (local.get $x) (local.get $y)) (local.get $x)))

  (func (export "f64.recoding_lt") (param $x f64) (param $y f64) (result i32)
    (f64.lt (f64.mul (local.get $x) (local.get $y)) (local.get $x)))

  (func (export "recoding_demote") (param $x f64) (param $y f32) (result f32)
    (f32.mul (f32.demote_f64 (local.get $x)) (local.get $y)))
)
