(module
    (func (export "f32x4.relaxed_madd") (param v128 v128 v128) (result v128) (f32x4.relaxed_madd (local.get 0) (local.get 1) (local.get 2)))
    (func (export "f32x4.relaxed_nmadd") (param v128 v128 v128) (result v128) (f32x4.relaxed_nmadd (local.get 0) (local.get 1) (local.get 2)))
    (func (export "f64x2.relaxed_nmadd") (param v128 v128 v128) (result v128) (f64x2.relaxed_nmadd (local.get 0) (local.get 1) (local.get 2)))
    (func (export "f64x2.relaxed_madd") (param v128 v128 v128) (result v128) (f64x2.relaxed_madd (local.get 0) (local.get 1) (local.get 2)))

    (func (export "f32x4.relaxed_madd_cmp") (param v128 v128 v128) (result v128)
          (f32x4.eq
            (f32x4.relaxed_madd (local.get 0) (local.get 1) (local.get 2))
            (f32x4.relaxed_madd (local.get 0) (local.get 1) (local.get 2))))
    (func (export "f32x4.relaxed_nmadd_cmp") (param v128 v128 v128) (result v128)
          (f32x4.eq
            (f32x4.relaxed_nmadd (local.get 0) (local.get 1) (local.get 2))
            (f32x4.relaxed_nmadd (local.get 0) (local.get 1) (local.get 2))))
    (func (export "f64x2.relaxed_nmadd_cmp") (param v128 v128 v128) (result v128)
          (f64x2.eq
            (f64x2.relaxed_nmadd (local.get 0) (local.get 1) (local.get 2))
            (f64x2.relaxed_nmadd (local.get 0) (local.get 1) (local.get 2))))
    (func (export "f64x2.relaxed_madd_cmp") (param v128 v128 v128) (result v128)
          (f64x2.eq
            (f64x2.relaxed_madd (local.get 0) (local.get 1) (local.get 2))
            (f64x2.relaxed_madd (local.get 0) (local.get 1) (local.get 2))))
)
