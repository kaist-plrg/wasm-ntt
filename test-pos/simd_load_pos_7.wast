(module (memory 1)
  (data (offset (i32.const 0))  "\02\00\00\00\02\00\00\00\02\00\00\00\02\00\00\00")
  (data (offset (i32.const 16)) "\03\00\00\00\03\00\00\00\03\00\00\00\03\00\00\00")
  (func (export "as-add/sub-operand") (result v128)
    ;; 2 2 2 2 + 3 3 3 3 = 5 5 5 5
    ;; 5 5 5 5 - 3 3 3 3 = 2 2 2 2
    (i8x16.sub
      (i8x16.add (v128.load (i32.const 0)) (v128.load (i32.const 16)))
      (v128.load (i32.const 16))
    )
  )
)
