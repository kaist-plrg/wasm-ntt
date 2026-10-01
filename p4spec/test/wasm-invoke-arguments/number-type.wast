(module (func (export "f") (param f32) (result f32) (local.get 0)))
(assert_return (invoke "f" (i32.const 0)) (f32.const 0))
