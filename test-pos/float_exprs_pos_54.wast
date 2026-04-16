(module
  (func (export "llvm_pr27153") (param $x i32) (result f32)
    (f32.add (f32.convert_i32_s (i32.and (local.get $x) (i32.const 268435455))) (f32.const -8388608.0))
  )
)
