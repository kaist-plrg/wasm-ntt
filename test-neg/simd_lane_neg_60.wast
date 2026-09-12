(assert_invalid (module (func (result v128)
  (i8x16.swizzle (i32.const 1) (v128.const i8x16 15 14 13 12 11 10 9 8 7 6 5 4 3 2 1 0)))) "type mismatch")
