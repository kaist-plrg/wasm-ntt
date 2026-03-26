(module (memory 1)
  (data (offset (i32.const 0)) "\64\65\66\67\68\69\6a\6b\6c\6d\6e\6f\70\71\72\73")  ;; 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115
  (data (offset (i32.const 16)) "\0f\0e\0d\0c\0b\0a\09\08\07\06\05\04\03\02\01\00")  ;;  15  14  13  12  11  10  09  08  07  06  05  04  03  02  01  00
  (func (export "as-i8x16.swizzle-operand") (result v128)
    (i8x16.swizzle (v128.load (i32.const 0)) (v128.load offset=15 (i32.const 1)))
  )
)
