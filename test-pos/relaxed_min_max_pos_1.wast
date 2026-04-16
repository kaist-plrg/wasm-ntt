(module
    (func (export "f32x4.relaxed_min") (param v128 v128) (result v128) (f32x4.relaxed_min (local.get 0) (local.get 1)))
    (func (export "f32x4.relaxed_max") (param v128 v128) (result v128) (f32x4.relaxed_max (local.get 0) (local.get 1)))
    (func (export "f64x2.relaxed_min") (param v128 v128) (result v128) (f64x2.relaxed_min (local.get 0) (local.get 1)))
    (func (export "f64x2.relaxed_max") (param v128 v128) (result v128) (f64x2.relaxed_max (local.get 0) (local.get 1)))

    (func (export "f32x4.relaxed_min_cmp") (param v128 v128) (result v128)
          (i32x4.eq
            (f32x4.relaxed_min (local.get 0) (local.get 1))
            (f32x4.relaxed_min (local.get 0) (local.get 1))))
    (func (export "f32x4.relaxed_max_cmp") (param v128 v128) (result v128)
          (i32x4.eq
            (f32x4.relaxed_max (local.get 0) (local.get 1))
            (f32x4.relaxed_max (local.get 0) (local.get 1))))
    (func (export "f64x2.relaxed_min_cmp") (param v128 v128) (result v128)
          (i64x2.eq
            (f64x2.relaxed_min (local.get 0) (local.get 1))
            (f64x2.relaxed_min (local.get 0) (local.get 1))))
    (func (export "f64x2.relaxed_max_cmp") (param v128 v128) (result v128)
          (i64x2.eq
            (f64x2.relaxed_max (local.get 0) (local.get 1))
            (f64x2.relaxed_max (local.get 0) (local.get 1))))
)
