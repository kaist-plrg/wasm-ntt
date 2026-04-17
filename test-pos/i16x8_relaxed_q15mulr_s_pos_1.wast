(module
    (func (export "i16x8.relaxed_q15mulr_s") (param v128 v128) (result v128) (i16x8.relaxed_q15mulr_s (local.get 0) (local.get 1)))

    (func (export "i16x8.relaxed_q15mulr_s_cmp") (param v128 v128) (result v128)
          (i16x8.eq
            (i16x8.relaxed_q15mulr_s (local.get 0) (local.get 1))
            (i16x8.relaxed_q15mulr_s (local.get 0) (local.get 1))))
)
