(module
    (func (export "i8x16.relaxed_laneselect") (param v128 v128 v128) (result v128) (i8x16.relaxed_laneselect (local.get 0) (local.get 1) (local.get 2)))
    (func (export "i16x8.relaxed_laneselect") (param v128 v128 v128) (result v128) (i16x8.relaxed_laneselect (local.get 0) (local.get 1) (local.get 2)))
    (func (export "i32x4.relaxed_laneselect") (param v128 v128 v128) (result v128) (i32x4.relaxed_laneselect (local.get 0) (local.get 1) (local.get 2)))
    (func (export "i64x2.relaxed_laneselect") (param v128 v128 v128) (result v128) (i64x2.relaxed_laneselect (local.get 0) (local.get 1) (local.get 2)))

    (func (export "i8x16.relaxed_laneselect_cmp") (param v128 v128 v128) (result v128)
          (i8x16.eq
            (i8x16.relaxed_laneselect (local.get 0) (local.get 1) (local.get 2))
            (i8x16.relaxed_laneselect (local.get 0) (local.get 1) (local.get 2))))
    (func (export "i16x8.relaxed_laneselect_cmp") (param v128 v128 v128) (result v128)
          (i16x8.eq
            (i16x8.relaxed_laneselect (local.get 0) (local.get 1) (local.get 2))
            (i16x8.relaxed_laneselect (local.get 0) (local.get 1) (local.get 2))))
    (func (export "i32x4.relaxed_laneselect_cmp") (param v128 v128 v128) (result v128)
          (i32x4.eq
            (i32x4.relaxed_laneselect (local.get 0) (local.get 1) (local.get 2))
            (i32x4.relaxed_laneselect (local.get 0) (local.get 1) (local.get 2))))
    (func (export "i64x2.relaxed_laneselect_cmp") (param v128 v128 v128) (result v128)
          (i64x2.eq
            (i64x2.relaxed_laneselect (local.get 0) (local.get 1) (local.get 2))
            (i64x2.relaxed_laneselect (local.get 0) (local.get 1) (local.get 2))))
)
