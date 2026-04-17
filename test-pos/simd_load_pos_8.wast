(module (memory 1)
  (data (offset (i32.const 0))  "\00\00\00\43\00\00\80\3f\66\66\e6\3f\00\00\80\bf")  ;; 128 1.0 1.8 -1
  (data (offset (i32.const 16)) "\00\00\00\40\00\00\00\40\00\00\00\40\00\00\00\40")  ;; 2.0 2.0 2.0 2.0
  (func (export "as-f32x4.mul-operand") (result v128)
    (f32x4.mul (v128.load (i32.const 0)) (v128.load (i32.const 16)))
  )
)
