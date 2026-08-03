(module
    (func (export "i8x16.relaxed_swizzle") (param v128 v128) (result v128) (i8x16.relaxed_swizzle (local.get 0) (local.get 1)))

    (func (export "i8x16.relaxed_swizzle_cmp") (param v128 v128) (result v128)
          (i8x16.eq
            (i8x16.relaxed_swizzle (local.get 0) (local.get 1))
            (i8x16.relaxed_swizzle (local.get 0) (local.get 1))))
)
