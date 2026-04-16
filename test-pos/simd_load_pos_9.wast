(module (memory 1)
  (data (offset (i32.const 0)) "\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff")  ;; 1111 ...
  (func (export "as-f32x4.abs-operand") (result v128)
    (f32x4.abs (v128.load (i32.const 0)))
  )
)
