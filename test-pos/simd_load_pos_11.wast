(module (memory 1)
  (data (offset (i32.const 0))  "\00\00\00\43\00\00\80\3f\66\66\e6\3f\00\00\80\bf")  ;; 128 1.0 1.8 -1
  (func (export "as-i32x4.trunc_sat_f32x4_s-operand") (result v128)
    (i32x4.trunc_sat_f32x4_s (v128.load (i32.const 0)))
  )
)
