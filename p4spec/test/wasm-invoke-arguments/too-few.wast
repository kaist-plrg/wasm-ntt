(module (func (export "f") (param i32) (result i32) (local.get 0)))
(assert_return (invoke "f") (i32.const 0))
