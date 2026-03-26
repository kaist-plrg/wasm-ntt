(module
  (func (export "llvm_pr27036") (param $x i32) (param $y i32) (result f32)
    (f32.add (f32.convert_i32_s (i32.or (local.get $x) (i32.const -25034805)))
             (f32.convert_i32_s (i32.and (local.get $y) (i32.const 14942208))))
  )
)
