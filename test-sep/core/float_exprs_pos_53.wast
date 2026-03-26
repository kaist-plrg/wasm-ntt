(module
  (func (export "llvm_pr26746") (param $x f32) (result f32)
    (f32.sub (f32.const 0.0) (f32.sub (f32.const -0.0) (local.get $x)))
  )
)
